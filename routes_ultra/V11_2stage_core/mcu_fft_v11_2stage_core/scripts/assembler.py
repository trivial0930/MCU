#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

OPCODES = {
    "NOP": 0x0,
    "ADD": 0x1,
    "SUB": 0x2,
    "AND": 0x3,
    "OR": 0x4,
    "MOVI": 0x5,
    "MOVR": 0x6,
    "LDR": 0x7,
    "STR": 0x8,
    "B": 0x9,
    "BL": 0xA,
    "CMP": 0xB,
    "BEQ": 0xC,
    "BNE": 0xD,
    "MUL": 0xE,
    "HALT": 0xF,
}


def strip_comment(line):
    return line.split(";", 1)[0].strip()


def parse_number(text, symbols):
    text = text.strip()
    if text.startswith("#"):
        text = text[1:].strip()
    if text in symbols:
        return symbols[text]
    return int(text, 0)


def reg(text):
    text = text.strip().upper()
    if not re.fullmatch(r"R(1[0-5]|[0-9])", text):
        raise ValueError(f"bad register: {text}")
    return int(text[1:])


def split_operands(text):
    out = []
    cur = []
    depth = 0
    for ch in text:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur:
        out.append("".join(cur).strip())
    return out


def parse_mem_operand(text, symbols):
    m = re.fullmatch(r"\[\s*(R(?:1[0-5]|[0-9]))\s*(?:\+\s*([#]?[A-Za-z_][A-Za-z0-9_]*|[#]?-?0x[0-9a-fA-F]+|[#]?-?\d+))?\s*\]", text)
    if not m:
        raise ValueError(f"bad memory operand: {text}")
    base = reg(m.group(1))
    imm = parse_number(m.group(2) or "0", symbols)
    return base, imm


def collect_lines(path):
    lines = []
    symbols = {}
    pc = 0
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = strip_comment(raw)
        if not line:
            continue
        if line.lower().startswith(".equ"):
            parts = re.split(r"[\s,]+", line, maxsplit=2)
            if len(parts) != 3:
                raise ValueError(f"bad .equ: {line}")
            symbols[parts[1]] = parse_number(parts[2], symbols)
            continue
        while ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip()
            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", label):
                raise ValueError(f"bad label: {label}")
            symbols[label] = pc
            line = rest.strip()
            if not line:
                break
        if line:
            lines.append(line)
            pc += 1
    return lines, symbols


def imm16(value):
    if not -32768 <= value <= 65535:
        raise ValueError(f"immediate out of 16-bit range: {value}")
    return value & 0xFFFF


def encode(line, symbols):
    parts = line.split(None, 1)
    mnemonic = parts[0].upper()
    operands = split_operands(parts[1] if len(parts) > 1 else "")
    if mnemonic not in OPCODES:
        raise ValueError(f"unknown instruction: {mnemonic}")
    op = OPCODES[mnemonic]
    rd = rs1 = rs2 = imm = 0

    if mnemonic == "NOP" or mnemonic == "HALT":
        pass
    elif mnemonic in ("ADD", "SUB", "AND", "OR", "MUL"):
        if len(operands) != 3:
            raise ValueError(f"{mnemonic} needs 3 operands")
        rd, rs1, rs2 = reg(operands[0]), reg(operands[1]), reg(operands[2])
    elif mnemonic == "MOVI":
        if len(operands) != 2:
            raise ValueError("MOVI needs 2 operands")
        rd, imm = reg(operands[0]), parse_number(operands[1], symbols)
    elif mnemonic == "MOVR":
        if len(operands) != 2:
            raise ValueError("MOVR needs 2 operands")
        rd, rs1 = reg(operands[0]), reg(operands[1])
    elif mnemonic == "LDR":
        if len(operands) != 2:
            raise ValueError("LDR needs 2 operands")
        rd = reg(operands[0])
        rs1, imm = parse_mem_operand(operands[1], symbols)
    elif mnemonic == "STR":
        if len(operands) != 2:
            raise ValueError("STR needs 2 operands")
        rs2 = reg(operands[0])
        rs1, imm = parse_mem_operand(operands[1], symbols)
    elif mnemonic in ("B", "BL", "BEQ", "BNE"):
        if len(operands) != 1:
            raise ValueError(f"{mnemonic} needs 1 operand")
        imm = parse_number(operands[0], symbols)
    elif mnemonic == "CMP":
        if len(operands) != 2:
            raise ValueError("CMP needs 2 operands")
        rs1, rs2 = reg(operands[0]), reg(operands[1])

    return (op << 28) | (rd << 24) | (rs1 << 20) | (rs2 << 16) | imm16(imm)


def write_mem(path, words):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(f"{w:08x}" for w in words) + "\n", encoding="utf-8")


def write_coe(path, words):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    body = ",\n".join(f"{w:08x}" for w in words)
    Path(path).write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        f"{body};\n",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("asm")
    parser.add_argument("-o", "--out", required=True)
    parser.add_argument("--coe")
    args = parser.parse_args()

    lines, symbols = collect_lines(args.asm)
    words = []
    for i, line in enumerate(lines):
        try:
            words.append(encode(line, symbols))
        except Exception as exc:
            raise SystemExit(f"{args.asm}:{i + 1}: {line}: {exc}")

    write_mem(args.out, words)
    if args.coe:
        write_coe(args.coe, words)
    print(f"assembled {len(words)} instructions")


if __name__ == "__main__":
    main()
