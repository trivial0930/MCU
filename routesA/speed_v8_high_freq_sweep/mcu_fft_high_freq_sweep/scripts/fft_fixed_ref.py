#!/usr/bin/env python3
import argparse
from pathlib import Path

C_Q15 = 23170


def to_s16(x: int) -> int:
    x &= 0xFFFF
    return x - 0x10000 if x & 0x8000 else x


def to_s32(x: int) -> int:
    x &= 0xFFFFFFFF
    return x - 0x100000000 if x & 0x80000000 else x


def sat16(x: int) -> int:
    if x > 32767:
        return 32767
    if x < -32768:
        return -32768
    return x


def q15_mul(a: int, b: int) -> int:
    return to_s32((to_s32(a) * to_s32(b)) >> 15)


def add32(a, b):
    return to_s32(a + b)


def sub32(a, b):
    return to_s32(a - b)


def butterfly_w0(ar, ai, br, bi):
    tr, ti = br, bi
    return add32(ar, tr), add32(ai, ti), sub32(ar, tr), sub32(ai, ti)


def butterfly_w1(ar, ai, br, bi):
    tr = q15_mul(add32(br, bi), C_Q15)
    ti = q15_mul(sub32(bi, br), C_Q15)
    return add32(ar, tr), add32(ai, ti), sub32(ar, tr), sub32(ai, ti)


def butterfly_w2(ar, ai, br, bi):
    tr = bi
    ti = sub32(0, br)
    return add32(ar, tr), add32(ai, ti), sub32(ar, tr), sub32(ai, ti)


def butterfly_w3(ar, ai, br, bi):
    tr = q15_mul(sub32(bi, br), C_Q15)
    ti = q15_mul(sub32(0, add32(br, bi)), C_Q15)
    return add32(ar, tr), add32(ai, ti), sub32(ar, tr), sub32(ai, ti)


def apply_bfly(data, i, j, fn):
    ar, ai = data[i]
    br, bi = data[j]
    aor, aoi, bor, boi = fn(ar, ai, br, bi)
    data[i] = (aor, aoi)
    data[j] = (bor, boi)


def fft8_dif_fixed(inputs):
    if len(inputs) != 8:
        raise ValueError("fft8_dif_fixed expects 8 complex samples")
    data = [(to_s32(r), to_s32(i)) for r, i in inputs]

    apply_bfly(data, 0, 4, butterfly_w0)
    apply_bfly(data, 1, 5, butterfly_w1)
    apply_bfly(data, 2, 6, butterfly_w2)
    apply_bfly(data, 3, 7, butterfly_w3)

    apply_bfly(data, 0, 2, butterfly_w0)
    apply_bfly(data, 1, 3, butterfly_w2)
    apply_bfly(data, 4, 6, butterfly_w0)
    apply_bfly(data, 5, 7, butterfly_w2)

    apply_bfly(data, 0, 1, butterfly_w0)
    apply_bfly(data, 2, 3, butterfly_w0)
    apply_bfly(data, 4, 5, butterfly_w0)
    apply_bfly(data, 6, 7, butterfly_w0)

    order = [0, 4, 2, 6, 1, 5, 3, 7]
    return [(to_s16(data[i][0]), to_s16(data[i][1])) for i in order]


def read_mem16(path):
    values = []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        text = raw.strip().rstrip(",;")
        if not text or text.startswith("memory_"):
            continue
        values.append(to_s16(int(text, 16) if all(c in "0123456789abcdefABCDEF" for c in text) else int(text, 0)))
    if len(values) != 16:
        raise ValueError(f"{path} must contain 16 words, got {len(values)}")
    return [(values[i], values[i + 1]) for i in range(0, 16, 2)]


def write_output(path, values):
    out = []
    for r, i in values:
        out.append(str(r))
        out.append(str(i))
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(out) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--out")
    args = parser.parse_args()
    result = fft8_dif_fixed(read_mem16(args.input))
    if args.out:
        write_output(args.out, result)
    else:
        for idx, (r, i) in enumerate(result):
            print(f"{idx}: {r} {i}")


if __name__ == "__main__":
    main()
