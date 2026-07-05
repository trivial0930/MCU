#!/usr/bin/env python3
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def to_s16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def parse_words(path):
    text = Path(path).read_text(encoding="utf-8")
    if "memory_initialization_vector" in text:
        text = text.split("memory_initialization_vector", 1)[1]
    words = []
    for token in re.findall(r"(?:0x)?[0-9a-fA-F]+", text):
        if token.lower().startswith("0x"):
            value = int(token, 16)
        elif any(c in "abcdefABCDEF" for c in token):
            value = int(token, 16)
        elif len(token) == 4:
            value = int(token, 16)
        else:
            value = int(token, 10)
        words.append(to_s16(value))
    return words


def emit_component_term(lines, acc, bucket, value_reg, coeff):
    if coeff == 0:
        return False
    if coeff == 128:
        lines.append(f"    ADD {acc}, {acc}, {value_reg}")
        return False
    if coeff == -128:
        lines.append(f"    SUB {acc}, {acc}, {value_reg}")
        return False
    if coeff == 91:
        lines.append(f"    ADD {bucket}, {bucket}, {value_reg}")
        return True
    if coeff == -91:
        lines.append(f"    SUB {bucket}, {bucket}, {value_reg}")
        return True
    raise ValueError(f"unsupported Q7 coefficient {coeff}")


def pair_sign(words, k, p):
    wr0 = words[p * 8 + k]
    wi0 = words[64 + p * 8 + k]
    wr1 = words[(p + 4) * 8 + k]
    wi1 = words[64 + (p + 4) * 8 + k]
    if wr1 == wr0 and wi1 == wi0:
        return "ADD"
    if wr1 == -wr0 and wi1 == -wi0:
        return "SUB"
    raise ValueError(f"unexpected pair relation for k={k} p={p}: {(wr0, wi0)} {(wr1, wi1)}")


def component_coeffs(words, k, p, component):
    wr = words[p * 8 + k]
    wi = words[64 + p * 8 + k]
    if component == "real":
        return wr, -wi
    if component == "imag":
        return wi, wr
    raise ValueError(component)


def generate_component_core(core_id, words):
    if core_id < 8:
        k = core_id
        component = "real"
        verify_addr = core_id
    else:
        k = core_id - 8
        component = "imag"
        verify_addr = core_id

    lines = [
        ".equ TEST_BASE, 0x1000",
        ".equ VERIFY_BASE, 0x2000",
        ".equ C_Q7, 91",
        "",
        "start:",
        "    MOVI R5, #VERIFY_BASE",
        "    MOVI R7, #TEST_BASE",
        "    MOVI R6, #C_Q7",
        "",
        f"; Core{core_id} owns {component}(X{k}) and writes verify address {verify_addr}.",
    ]

    uses_q91 = False
    for p in range(4):
        op = pair_sign(words, k, p)
        wr = words[p * 8 + k]
        wi = words[64 + p * 8 + k]
        coeff_r, coeff_i = component_coeffs(words, k, p, component)
        lines += [
            "",
            f"; Pair n={p} and n={p + 4}, W({p},{k})=({wr},{wi})",
            f"    LDR R8, [R7 + {128 + p}]",
            f"    LDR R9, [R7 + {136 + p}]",
            f"    LDR R10, [R7 + {128 + p + 4}]",
            f"    LDR R11, [R7 + {136 + p + 4}]",
            f"    {op} R8, R8, R10",
            f"    {op} R9, R9, R11",
        ]
        uses_q91 |= emit_component_term(lines, "R12", "R14", "R8", coeff_r)
        uses_q91 |= emit_component_term(lines, "R12", "R14", "R9", coeff_i)

    if uses_q91:
        lines += [
            "",
            "; Fold +/-91 bucket with one ordinary MUL instruction.",
            "    MUL R14, R14, R6",
            "    ADD R12, R12, R14",
        ]

    lines += [
        "",
        f"    STR R12, [R5 + {verify_addr}]",
        "    HALT",
        "",
    ]
    return "\n".join(lines)


def main():
    words = parse_words(ROOT / "mem" / "FFT_input.coe")
    asm_dir = ROOT / "asm"
    asm_dir.mkdir(exist_ok=True)
    for core_id in range(16):
        component = "real" if core_id < 8 else "imag"
        k = core_id if core_id < 8 else core_id - 8
        name = f"fft8_core{core_id:02d}_{component}_x{k}.asm"
        path = asm_dir / name
        path.write_text(generate_component_core(core_id, words), encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
