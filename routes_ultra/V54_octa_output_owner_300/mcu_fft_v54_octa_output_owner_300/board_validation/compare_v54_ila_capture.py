#!/usr/bin/env python3
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOARD = ROOT / "board_validation"
CAPTURE = BOARD / "v54_ila_verify_we_capture.csv"
EXPECTED = ROOT / "results" / "expected_fft_output.txt"
OUT = BOARD / "v54_hw_compare.csv"
STATUS = BOARD / "v54_hw_compare_status.txt"


def norm_hex(value):
    value = value.strip().lower()
    if value.startswith("0x"):
        value = value[2:]
    return value.zfill(4)[-4:]


def parse_int(value):
    value = value.strip().lower().replace("_", "")
    if not value:
        return 0
    if "'" in value:
        base = value.split("'")[-1][0]
        digits = value.split("'")[-1][1:]
        if base == "h":
            return int(digits.replace("x", "0"), 16)
        if base == "b":
            return int(digits.replace("x", "0"), 2)
        if base == "d":
            return int(digits.replace("x", "0"), 10)
    if value.startswith("0x"):
        return int(value, 16)
    if all(ch in "01" for ch in value) and len(value) > 8:
        return int(value, 2)
    return int(value, 16)


def find_column(header, token):
    matches = [i for i, name in enumerate(header) if token in name]
    if not matches:
        raise SystemExit(f"missing column containing {token!r}")
    return matches[0]


def main():
    expected = [norm_hex(line) for line in EXPECTED.read_text(encoding="utf-8").splitlines() if line.strip()]
    if len(expected) != 16:
        raise SystemExit(f"expected 16 output words, got {len(expected)}")

    with CAPTURE.open(newline="", encoding="utf-8-sig") as f:
        rows = list(csv.reader(f))
    if len(rows) < 3:
        raise SystemExit("ILA capture CSV is too short")

    header = rows[0]
    idx_sample = find_column(header, "Sample in Buffer")
    idx_data = find_column(header, "verify_vector_out_all")
    idx_we = find_column(header, "verify_we_all")
    idx_addr = find_column(header, "verify_addr_all")
    idx_cnt = find_column(header, "cnt_test")
    idx_done = find_column(header, "done")

    writes = []
    done_cnts = []
    for row in rows[2:]:
        if len(row) < len(header):
            continue
        sample = int(row[idx_sample], 0)
        data_bus = parse_int(row[idx_data])
        we_mask = parse_int(row[idx_we])
        addr_bus = parse_int(row[idx_addr])
        cnt = parse_int(row[idx_cnt])
        done = parse_int(row[idx_done]) != 0
        if done:
            done_cnts.append(cnt)
        for core in range(8):
            if not (we_mask & (1 << core)):
                continue
            addr = (addr_bus >> (core * 5)) & 0x1F
            data = f"{(data_bus >> (core * 16)) & 0xFFFF:04x}"
            writes.append((addr, data, cnt, sample, core, f"0x{we_mask:02x}", int(done)))

    first_by_addr = {}
    for item in writes:
        first_by_addr.setdefault(item[0], item)

    lines = [["addr", "captured_hex", "expected_hex", "cnt_test_at_write", "sample", "writer_core", "we_mask", "done", "status"]]
    ok = True
    for addr in range(16):
        if addr not in first_by_addr:
            lines.append([addr, "", expected[addr], "", "", "", "", "", "MISSING"])
            ok = False
            continue
        _, data, cnt, sample, core, we_mask, done = first_by_addr[addr]
        status = "PASS" if data == expected[addr] else "FAIL"
        if status != "PASS":
            ok = False
        lines.append([addr, data, expected[addr], cnt, sample, core, we_mask, done, status])

    with OUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(lines)

    last_addr = writes[-1][0] if writes else None
    last_cnt = writes[-1][2] if writes else None
    final_done_cnt = done_cnts[-1] if done_cnts else None
    pass_status = ok and len(writes) == 16 and len(first_by_addr) == 16 and last_addr == 15
    summary = [
        f"write_count={len(writes)}",
        f"unique_addr_count={len(first_by_addr)}",
        f"last_write_addr={last_addr}",
        f"last_write_cnt_test={last_cnt}",
        f"final_done_cnt_test={final_done_cnt}",
        f"compare_status={'PASS' if pass_status else 'FAIL'}",
        "csv=board_validation/v54_hw_compare.csv",
    ]
    STATUS.write_text("\n".join(summary) + "\n", encoding="utf-8")
    print("\n".join(summary))
    if not pass_status:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
