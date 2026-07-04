#!/usr/bin/env python3
import argparse
import random
from pathlib import Path


def to_u16(x):
    return x & 0xFFFF


def write_mem(path, values):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(f"{to_u16(v):04x}" for v in values) + "\n", encoding="utf-8")


def write_coe(path, values):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    body = ",\n".join(f"{to_u16(v):04x}" for v in values)
    Path(path).write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        f"{body};\n",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--out", default="mem/test_vector.mem")
    parser.add_argument("--coe", default="mem/test_vector.coe")
    parser.add_argument("--limit", type=int, default=1024)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    values = [rng.randint(-args.limit, args.limit) for _ in range(16)]
    write_mem(args.out, values)
    write_coe(args.coe, values)
    print(f"generated 16 words with seed={args.seed}")


if __name__ == "__main__":
    main()
