#!/usr/bin/env python3
import argparse
import random
import re
from pathlib import Path


def to_s16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def to_u16(value):
    return value & 0xFFFF


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


def write_mem(path, words, depth=256):
    padded = list(words) + [0] * max(0, depth - len(words))
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(
        "\n".join(f"{to_u16(word):04x}" for word in padded[:depth]) + "\n",
        encoding="utf-8",
    )


def write_words(path, words):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(
        "\n".join(f"{to_u16(word):04x}" for word in words) + "\n",
        encoding="utf-8",
    )


def expected_from_fft_input(words):
    if len(words) < 144:
        raise ValueError(f"FFT input must contain at least 144 words, got {len(words)}")
    real_mat = words[:64]
    imag_mat = words[64:128]
    xr = words[128:136]
    xi = words[136:144]
    real_out = []
    imag_out = []

    for k in range(8):
        acc_r = 0
        acc_i = 0
        for n in range(8):
            wr = real_mat[n * 8 + k]
            wi = imag_mat[n * 8 + k]
            acc_r += xr[n] * wr - xi[n] * wi
            acc_i += xr[n] * wi + xi[n] * wr
        real_out.append(to_s16(acc_r))
        imag_out.append(to_s16(acc_i))
    return real_out + imag_out


def make_random_input(template_words, seed):
    rng = random.Random(seed)
    words = list(template_words[:144])
    # Keep values small enough that the 8-point DFT stays inside signed Q12 range.
    words[128:136] = [rng.randint(-12, 12) for _ in range(8)]
    words[136:144] = [rng.randint(-12, 12) for _ in range(8)]
    return words


def cmd_emit(args):
    words = parse_words(args.input_coe)
    expected = expected_from_fft_input(words)
    if args.expected_coe:
        official = parse_words(args.expected_coe)
        if official[:16] != expected:
            raise SystemExit("computed model does not match official FFT_output.coe")
    if args.mem:
        write_mem(args.mem, words)
    if args.expected:
        write_words(args.expected, expected)
    print("official model emit PASS")


def cmd_random(args):
    template = parse_words(args.template_coe)
    words = make_random_input(template, args.seed)
    expected = expected_from_fft_input(words)
    write_mem(args.mem, words)
    write_words(args.expected, expected)
    print(f"random seed {args.seed} generated")


def cmd_check(args):
    expected = parse_words(args.expected)
    got = parse_words(args.got)
    if len(expected) < 16 or len(got) < 16:
        raise SystemExit("expected and got files must contain at least 16 words")

    ok = True
    print("Index  Expected  Got      Status")
    for i, (exp, actual) in enumerate(zip(expected[:16], got[:16])):
        status = "PASS" if exp == actual else "FAIL"
        ok = ok and (status == "PASS")
        print(f"{i:<5}  {exp:<8}  {actual:<8} {status}")
    print(f"Overall: {'PASS' if ok else 'FAIL'}")
    raise SystemExit(0 if ok else 1)


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    emit = sub.add_parser("emit")
    emit.add_argument("--input-coe", required=True)
    emit.add_argument("--expected-coe")
    emit.add_argument("--mem")
    emit.add_argument("--expected")
    emit.set_defaults(func=cmd_emit)

    rnd = sub.add_parser("random")
    rnd.add_argument("--template-coe", required=True)
    rnd.add_argument("--seed", type=int, required=True)
    rnd.add_argument("--mem", required=True)
    rnd.add_argument("--expected", required=True)
    rnd.set_defaults(func=cmd_random)

    check = sub.add_parser("check")
    check.add_argument("--expected", required=True)
    check.add_argument("--got", required=True)
    check.set_defaults(func=cmd_check)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
