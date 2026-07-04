#!/usr/bin/env python3
import csv
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import assembler  # noqa: E402


def disassemble(asm_path, mem_path, out_path, core_name):
    lines, symbols = assembler.collect_lines(asm_path)
    words = [int(line.strip(), 16) for line in mem_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    counts = Counter()

    out = [
        f"# {core_name} disassembly",
        "",
        "pc, machine_word, opcode, instruction",
    ]
    for pc, line in enumerate(lines):
        mnemonic = line.split(None, 1)[0].upper()
        counts[mnemonic] += 1
        word = words[pc] if pc < len(words) else assembler.encode(line, symbols)
        out.append(f"{pc:04d}, 0x{word:08x}, {mnemonic}, {line}")

    out_path.write_text("\n".join(out) + "\n", encoding="utf-8")
    return counts


def write_opcode_summary(core_counts):
    out_csv = ROOT / "results" / "opcode_summary.csv"
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["core", "mnemonic", "opcode_hex", "count", "is_fft_special"])
        for core, counts in core_counts.items():
            for mnemonic, count in sorted(counts.items()):
                opcode = assembler.OPCODES.get(mnemonic)
                writer.writerow([core, mnemonic, f"0x{opcode:x}" if opcode is not None else "", count, "no"])


def write_verify_trace():
    src = ROOT / "board_validation" / "v34_hw_compare.csv"
    rows = []
    with src.open("r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rows.append(row)

    rows.sort(key=lambda row: int(row["sample"]))
    out_csv = ROOT / "results" / "verify_write_trace.csv"
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        fieldnames = [
            "write_order",
            "verify_addr",
            "captured_hex",
            "expected_hex",
            "cnt_test_at_write",
            "ila_sample",
            "done",
            "status",
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for order, row in enumerate(rows):
            writer.writerow({
                "write_order": order,
                "verify_addr": row["addr"],
                "captured_hex": row["captured_hex"],
                "expected_hex": row["expected_hex"],
                "cnt_test_at_write": row["cnt_test_at_write"],
                "ila_sample": row["sample"],
                "done": row["done"],
                "status": row["status"],
            })


def main():
    (ROOT / "results").mkdir(exist_ok=True)
    core_counts = {
        "Core0": disassemble(
            ROOT / "asm" / "fft8_official_sample.asm",
            ROOT / "mem" / "instr_fft8.mem",
            ROOT / "results" / "core0_disasm.txt",
            "Core0",
        ),
        "Core1": disassemble(
            ROOT / "asm" / "fft8_core1_output.asm",
            ROOT / "mem" / "instr_core1.mem",
            ROOT / "results" / "core1_disasm.txt",
            "Core1",
        ),
    }
    write_opcode_summary(core_counts)
    write_verify_trace()

    print("wrote results/core0_disasm.txt")
    print("wrote results/core1_disasm.txt")
    print("wrote results/opcode_summary.csv")
    print("wrote results/verify_write_trace.csv")


if __name__ == "__main__":
    main()
