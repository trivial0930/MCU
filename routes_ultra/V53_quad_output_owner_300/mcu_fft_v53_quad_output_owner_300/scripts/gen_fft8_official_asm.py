#!/usr/bin/env python3
import os
from pathlib import Path


CORE0_OUT = Path("asm/fft8_official_sample.asm")
CORE1_OUT = Path("asm/fft8_core1_output.asm")
CORE2_OUT = Path("asm/fft8_core2_output.asm")
CORE3_OUT = Path("asm/fft8_core3_output.asm")

CORE1_WAIT_STAGE2_NOP = int(os.environ.get("CORE1_WAIT_STAGE2_NOP", "68"))
CORE1_WAIT_STAGE3_NOP = int(os.environ.get("CORE1_WAIT_STAGE3_NOP", "23"))
CORE2_WAIT_STAGE3_NOP = int(os.environ.get("CORE2_WAIT_STAGE3_NOP", "108"))
CORE3_WAIT_STAGE3_NOP = int(os.environ.get("CORE3_WAIT_STAGE3_NOP", "92"))


def emit_loads_from_ram(lines, a, b):
    ar, ai = 2 * a, 2 * a + 1
    br, bi = 2 * b, 2 * b + 1
    lines += [
        f"    LDR R8, [R0 + {ar}]",
        f"    LDR R9, [R0 + {ai}]",
        f"    LDR R10, [R0 + {br}]",
        f"    LDR R11, [R0 + {bi}]",
    ]


def emit_loads_from_test_rom(lines, a, b):
    lines += [
        f"    LDR R8, [R7 + {128 + a}]",
        f"    LDR R9, [R7 + {136 + a}]",
        f"    LDR R10, [R7 + {128 + b}]",
        f"    LDR R11, [R7 + {136 + b}]",
    ]


def emit_math(lines, twiddle):
    lines += [
        "    ADD R12, R8, R10",
        "    ADD R13, R9, R11",
    ]

    if twiddle == 0:
        lines += [
            "    SUB R2, R8, R10",
            "    SUB R3, R9, R11",
        ]
        return "R2", "R3"
    if twiddle == 1:
        lines += [
            "    SUB R2, R8, R10",
            "    SUB R3, R9, R11",
            "    ADD R4, R2, R3",
            "    MUL R4, R4, R6",
            "    SUB R14, R3, R2",
            "    MUL R14, R14, R6",
        ]
        return "R4", "R14"
    if twiddle == 2:
        lines += [
            "    SUB R3, R9, R11",
            "    SUB R14, R10, R8",
        ]
        return "R3", "R14"
    if twiddle == 3:
        lines += [
            "    SUB R2, R8, R10",
            "    SUB R3, R9, R11",
            "    SUB R4, R3, R2",
            "    MUL R4, R4, R6",
            "    ADD R14, R2, R3",
            "    SUB R14, R0, R14",
            "    MUL R14, R14, R6",
        ]
        return "R4", "R14"
    raise ValueError(twiddle)


def emit_ram_stores(lines, a, b, lower_r, lower_i):
    ar, ai = 2 * a, 2 * a + 1
    lr, li = 2 * b, 2 * b + 1
    lines += [
        f"    STR R12, [R0 + {ar}]",
        f"    STR R13, [R0 + {ai}]",
        f"    STR {lower_r}, [R0 + {lr}]",
        f"    STR {lower_i}, [R0 + {li}]",
    ]


def emit_verify_stores(lines, upper_bin, lower_bin, lower_r, lower_i):
    lines += [
        f"    STR R12, [R5 + {upper_bin}]",
        f"    STR R13, [R5 + {upper_bin + 8}]",
        f"    STR {lower_r}, [R5 + {lower_bin}]",
        f"    STR {lower_i}, [R5 + {lower_bin + 8}]",
    ]


def emit_stage3_verify(lines, a, b, upper_bin, lower_bin):
    lines += ["", f"; Stage 3 owner butterfly({a}, {b}, W0)"]
    emit_loads_from_ram(lines, a, b)
    lower_r, lower_i = emit_math(lines, 0)
    emit_verify_stores(lines, upper_bin, lower_bin, lower_r, lower_i)


def write(path, lines):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {path}")


def core_header(extra_constants=True):
    lines = [
        ".equ TEST_BASE, 0x1000",
        ".equ VERIFY_BASE, 0x2000",
        ".equ RAM_BASE, 0x0000",
    ]
    if extra_constants:
        lines.append(".equ C_Q7, 91")
    lines += [
        "",
        "start:",
        "    MOVI R0, #RAM_BASE",
        "    MOVI R5, #VERIFY_BASE",
    ]
    if extra_constants:
        lines += [
            "    MOVI R6, #C_Q7",
            "    MOVI R7, #TEST_BASE",
        ]
    return lines


def build_core0():
    lines = core_header(extra_constants=True)
    lines += [
        "",
        "; Core0 keeps the Stage1/Stage2 producer chain and owns X0/X4.",
    ]

    for a, b, tw, stage in [
        (1, 5, 1, 1),
        (3, 7, 3, 1),
        (0, 4, 0, 1),
        (2, 6, 2, 1),
    ]:
        lines += ["", f"; Stage {stage}: DIF butterfly({a}, {b}, W{tw})"]
        emit_loads_from_test_rom(lines, a, b)
        lower_r, lower_i = emit_math(lines, tw)
        emit_ram_stores(lines, a, b, lower_r, lower_i)

    for a, b, tw, stage in [
        (4, 6, 0, 2),
        (0, 2, 0, 2),
        (1, 3, 2, 2),
    ]:
        lines += ["", f"; Stage {stage}: DIF butterfly({a}, {b}, W{tw})"]
        emit_loads_from_ram(lines, a, b)
        lower_r, lower_i = emit_math(lines, tw)
        emit_ram_stores(lines, a, b, lower_r, lower_i)

    emit_stage3_verify(lines, 0, 1, 0, 4)
    lines += ["", "    HALT"]
    return lines


def build_core1():
    lines = core_header(extra_constants=False)
    lines += [
        "",
        "; Core1 computes Stage2 butterfly(5,7,W2) and owns X1/X5.",
    ]
    lines += ["    NOP"] * CORE1_WAIT_STAGE2_NOP
    lines += ["", "; Core1 Stage 2: DIF butterfly(5, 7, W2)"]
    emit_loads_from_ram(lines, 5, 7)
    lower_r, lower_i = emit_math(lines, 2)
    emit_ram_stores(lines, 5, 7, lower_r, lower_i)
    lines += ["    NOP"] * CORE1_WAIT_STAGE3_NOP
    emit_stage3_verify(lines, 4, 5, 1, 5)
    lines += ["", "    HALT"]
    return lines


def build_core2():
    lines = core_header(extra_constants=False)
    lines += [
        "",
        "; Core2 owns X2/X6 and waits for Core0 Stage2(1,3,W2).",
    ]
    lines += ["    NOP"] * CORE2_WAIT_STAGE3_NOP
    emit_stage3_verify(lines, 2, 3, 2, 6)
    lines += ["", "    HALT"]
    return lines


def build_core3():
    lines = core_header(extra_constants=False)
    lines += [
        "",
        "; Core3 owns X3/X7 and waits for Core1 Stage2(5,7,W2).",
    ]
    lines += ["    NOP"] * CORE3_WAIT_STAGE3_NOP
    emit_stage3_verify(lines, 6, 7, 3, 7)
    lines += ["", "    HALT"]
    return lines


def main():
    write(CORE0_OUT, build_core0())
    write(CORE1_OUT, build_core1())
    write(CORE2_OUT, build_core2())
    write(CORE3_OUT, build_core3())


if __name__ == "__main__":
    main()
