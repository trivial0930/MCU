#!/usr/bin/env python3
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mem")
    parser.add_argument("-o", "--out", required=True)
    parser.add_argument("--width", type=int, default=16)
    args = parser.parse_args()

    words = [line.strip() for line in Path(args.mem).read_text(encoding="utf-8").splitlines() if line.strip()]
    body = ",\n".join(words)
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        f"{body};\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
