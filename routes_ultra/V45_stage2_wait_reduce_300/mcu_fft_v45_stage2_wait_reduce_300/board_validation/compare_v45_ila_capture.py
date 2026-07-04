#!/usr/bin/env python3
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOARD = ROOT / "board_validation"
CAPTURE = BOARD / "v45_ila_verify_we_capture.csv"
EXPECTED = ROOT / "results" / "expected_fft_output.txt"
OUT = BOARD / "v45_hw_compare.csv"
STATUS = BOARD / "v45_hw_compare_status.txt"


def norm_hex(value):
    value = value.strip().lower()
    if value.startswith("0x"):
        value = value[2:]
    return value.zfill(4)[-4:]


def parse_logic(value):
    return value.strip().lower() in {"1", "01", "1'b1"}


def main():
    expected = [norm_hex(line) for line in EXPECTED.read_text(encoding="utf-8").splitlines() if line.strip()]
    if len(expected) != 16:
        raise SystemExit(f"expected 16 output words, got {len(expected)}")

    with CAPTURE.open(newline="", encoding="utf-8-sig") as f:
        rows = list(csv.reader(f))
    if len(rows) < 3:
        raise SystemExit("ILA capture CSV is too short")

    header = rows[0]
    idx = {name: i for i, name in enumerate(header)}
    data_rows = rows[2:]
    required = [
        "Sample in Buffer",
        "u_ila_probe/verify_vector_out[15:0]",
        "u_ila_probe/verify_we",
        "u_ila_probe/verify_addr[4:0]",
        "u_ila_probe/cnt_test[19:0]",
        "u_ila_probe/done",
    ]
    missing = [name for name in required if name not in idx]
    if missing:
        raise SystemExit(f"missing columns: {missing}")

    writes = []
    for row in data_rows:
        if len(row) < len(header):
            continue
        if not parse_logic(row[idx["u_ila_probe/verify_we"]]):
            continue
        sample = int(row[idx["Sample in Buffer"]], 0)
        addr = int(row[idx["u_ila_probe/verify_addr[4:0]"]], 16)
        data = norm_hex(row[idx["u_ila_probe/verify_vector_out[15:0]"]])
        cnt = int(row[idx["u_ila_probe/cnt_test[19:0]"]], 16)
        done = row[idx["u_ila_probe/done"]].strip()
        writes.append((addr, data, cnt, sample, done))

    first_by_addr = {}
    for addr, data, cnt, sample, done in writes:
        first_by_addr.setdefault(addr, (data, cnt, sample, done))

    lines = [["addr", "captured_hex", "expected_hex", "cnt_test_at_write", "sample", "done", "status"]]
    ok = True
    for addr in range(16):
        if addr not in first_by_addr:
            lines.append([addr, "", expected[addr], "", "", "", "MISSING"])
            ok = False
            continue
        data, cnt, sample, done = first_by_addr[addr]
        status = "PASS" if data == expected[addr] else "FAIL"
        if status != "PASS":
            ok = False
        lines.append([addr, data, expected[addr], cnt, sample, done, status])

    with OUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(lines)

    last_addr = writes[-1][0] if writes else None
    last_cnt = writes[-1][2] if writes else None
    done_cnts = []
    for row in data_rows:
        if len(row) < len(header):
            continue
        if parse_logic(row[idx["u_ila_probe/done"]]):
            done_cnts.append(int(row[idx["u_ila_probe/cnt_test[19:0]"]], 16))
    final_done_cnt = done_cnts[-1] if done_cnts else None
    pass_status = ok and len(writes) >= 16 and len(first_by_addr) == 16
    summary = [
        f"write_count={len(writes)}",
        f"unique_addr_count={len(first_by_addr)}",
        f"last_write_addr={last_addr}",
        f"last_write_cnt_test={last_cnt}",
        f"final_done_cnt_test={final_done_cnt}",
        f"compare_status={'PASS' if pass_status else 'FAIL'}",
        "csv=board_validation/v45_hw_compare.csv",
    ]
    STATUS.write_text("\n".join(summary) + "\n", encoding="utf-8")
    print("\n".join(summary))
    if not pass_status:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
