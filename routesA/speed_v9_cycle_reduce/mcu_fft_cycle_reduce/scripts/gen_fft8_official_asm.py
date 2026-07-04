#!/usr/bin/env python3
from pathlib import Path


OUT = Path("asm/fft8_official_sample.asm")


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
        "    SUB R2, R8, R10",
        "    SUB R3, R9, R11",
    ]

    if twiddle == 0:
        return "R2", "R3"
    elif twiddle == 1:
        lines += [
            "    MADD91 R4, R2, R3",
            "    MSUB91 R5, R3, R2",
        ]
        return "R4", "R5"
    elif twiddle == 2:
        lines += [
            "    SUB R5, R1, R2",
        ]
        return "R3", "R5"
    elif twiddle == 3:
        lines += [
            "    MSUB91 R4, R3, R2",
            "    MNSUM91 R5, R2, R3",
        ]
        return "R4", "R5"
    else:
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
        f"    STR R12, [R14 + {upper_bin}]",
        f"    STR R13, [R14 + {upper_bin + 8}]",
        f"    STR {lower_r}, [R14 + {lower_bin}]",
        f"    STR {lower_i}, [R14 + {lower_bin + 8}]",
    ]


def main():
    lines = [
        ".equ TEST_BASE, 0x1000",
        ".equ VERIFY_BASE, 0x2000",
        ".equ RAM_BASE, 0x0000",
        "",
        "start:",
        "    MOVI R0, #RAM_BASE",
        "    MOVI R1, #0",
        "    MOVI R7, #TEST_BASE",
        "    MOVI R14, #VERIFY_BASE",
        "",
        "; Stage 1 reads official FFT input directly from test ROM.",
        "; ext_test_rom_if converts real[128:135]/imag[136:143] Q5 samples to Q12.",
    ]

    for a, b, tw, stage in [
        (0, 4, 0, 1),
        (1, 5, 1, 1),
        (2, 6, 2, 1),
        (3, 7, 3, 1),
    ]:
        lines += ["", f"; Stage {stage}: DIF butterfly({a}, {b}, W{tw})"]
        emit_loads_from_test_rom(lines, a, b)
        lower_r, lower_i = emit_math(lines, tw)
        emit_ram_stores(lines, a, b, lower_r, lower_i)

    for a, b, tw, stage in [
        (0, 2, 0, 2),
        (1, 3, 2, 2),
        (4, 6, 0, 2),
        (5, 7, 2, 2),
    ]:
        lines += ["", f"; Stage {stage}: DIF butterfly({a}, {b}, W{tw})"]
        emit_loads_from_ram(lines, a, b)
        lower_r, lower_i = emit_math(lines, tw)
        emit_ram_stores(lines, a, b, lower_r, lower_i)

    lines += [
        "",
        "; Stage 3 writes official layout directly to verify RAM.",
    ]

    for a, b, upper_bin, lower_bin in [
        (0, 1, 0, 4),
        (2, 3, 2, 6),
        (4, 5, 1, 5),
        (6, 7, 3, 7),
    ]:
        lines += ["", f"; Stage 3: DIF butterfly({a}, {b}, W0)"]
        emit_loads_from_ram(lines, a, b)
        lower_r, lower_i = emit_math(lines, 0)
        emit_verify_stores(lines, upper_bin, lower_bin, lower_r, lower_i)

    lines += ["", "    HALT", ""]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
