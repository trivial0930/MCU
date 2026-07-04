#!/usr/bin/env python3
import argparse
from pathlib import Path
from fft_fixed_ref import fft8_dif_fixed, read_mem16, to_s16


def parse_word(text):
    text = text.strip().rstrip(",;")
    if not text:
        return None
    if text.startswith("0x"):
        return to_s16(int(text, 16))
    if all(c in "0123456789abcdefABCDEF" for c in text) and any(c in "abcdefABCDEF" for c in text):
        return to_s16(int(text, 16))
    if len(text) == 4 and all(c in "0123456789abcdefABCDEF" for c in text):
        return to_s16(int(text, 16))
    return to_s16(int(text, 10))


def read_got(path):
    values = []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        word = parse_word(raw)
        if word is not None:
            values.append(word)
    if len(values) != 16:
        raise ValueError(f"{path} must contain 16 words, got {len(values)}")
    return [(values[i], values[i + 1]) for i in range(0, 16, 2)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="mem/test_vector.mem")
    parser.add_argument("--got", default="results/verify_output.txt")
    args = parser.parse_args()

    expected = fft8_dif_fixed(read_mem16(args.input))
    got = read_got(args.got)
    ok = True

    print("Index  Expected(real, imag)  Got(real, imag)  Status")
    for i, (exp, actual) in enumerate(zip(expected, got)):
        status = "PASS" if exp == actual else "FAIL"
        ok = ok and (status == "PASS")
        print(f"{i:<5}  {str(exp):<21} {str(actual):<16} {status}")
    print(f"Overall: {'PASS' if ok else 'FAIL'}")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
