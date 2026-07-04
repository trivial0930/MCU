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


def emit_term(lines, acc, value_reg, coeff, scaled_reg, scale_cache=None):
    if coeff == 0:
        return
    if coeff == 128:
        lines.append(f"    ADD {acc}, {acc}, {value_reg}")
    elif coeff == -128:
        lines.append(f"    SUB {acc}, {acc}, {value_reg}")
    elif coeff == 91:
        if scale_cache is not None:
            cached = scale_cache.get(value_reg)
            if cached is None:
                scale_cache[value_reg] = scaled_reg
                lines.append(f"    MUL {scaled_reg}, {value_reg}, R6")
            else:
                scaled_reg = cached
        else:
            lines.append(f"    MUL {scaled_reg}, {value_reg}, R6")
        lines.append(f"    ADD {acc}, {acc}, {scaled_reg}")
    elif coeff == -91:
        if scale_cache is not None:
            cached = scale_cache.get(value_reg)
            if cached is None:
                scale_cache[value_reg] = scaled_reg
                lines.append(f"    MUL {scaled_reg}, {value_reg}, R6")
            else:
                scaled_reg = cached
        else:
            lines.append(f"    MUL {scaled_reg}, {value_reg}, R6")
        lines.append(f"    SUB {acc}, {acc}, {scaled_reg}")
    else:
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


def generate_core(k, words):
    lines = [
        ".equ TEST_BASE, 0x1000",
        ".equ VERIFY_BASE, 0x2000",
        ".equ RAM_BASE, 0x0000",
        ".equ C_Q7, 91",
        "",
        "start:",
        "    MOVI R0, #RAM_BASE",
        "    MOVI R5, #VERIFY_BASE",
        "    MOVI R6, #C_Q7",
        "    MOVI R7, #TEST_BASE",
        "    MOVR R12, R0",
        "    MOVR R13, R0",
        "",
        f"; Core{k} owns complex output X{k}.",
    ]

    for p in range(4):
        op = pair_sign(words, k, p)
        wr = words[p * 8 + k]
        wi = words[64 + p * 8 + k]
        lines += [
            "",
            f"; Pair n={p} and n={p + 4}, coefficient W({p},{k})=({wr},{wi})",
            f"    LDR R8, [R7 + {128 + p}]",
            f"    LDR R9, [R7 + {136 + p}]",
            f"    LDR R10, [R7 + {128 + p + 4}]",
            f"    LDR R11, [R7 + {136 + p + 4}]",
            f"    {op} R8, R8, R10",
            f"    {op} R9, R9, R11",
        ]
        scale_cache = {}
        emit_term(lines, "R12", "R8", wr, "R14", scale_cache)
        emit_term(lines, "R12", "R9", -wi, "R15", scale_cache)
        emit_term(lines, "R13", "R8", wi, "R14", scale_cache)
        emit_term(lines, "R13", "R9", wr, "R15", scale_cache)

    lines += [
        "",
        f"    STR R12, [R5 + {k}]",
        f"    STR R13, [R5 + {k + 8}]",
        "    HALT",
        "",
    ]
    return "\n".join(lines)


def main():
    words = parse_words(ROOT / "mem" / "FFT_input.coe")
    asm_dir = ROOT / "asm"
    asm_dir.mkdir(exist_ok=True)
    for k in range(8):
        name = "fft8_official_sample.asm" if k == 0 else f"fft8_core{k}_output.asm"
        path = asm_dir / name
        path.write_text(generate_core(k, words), encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
