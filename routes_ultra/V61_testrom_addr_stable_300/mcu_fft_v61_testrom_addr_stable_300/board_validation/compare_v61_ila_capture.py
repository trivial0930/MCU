#!/usr/bin/env python3
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOARD = ROOT / "board_validation"
CAPTURE = BOARD / "v61_ila_fast_stop_capture.csv"
EXPECTED = ROOT / "results" / "expected_fft_output.txt"
OUT_COMPARE = BOARD / "v61_hw_compare.csv"
OUT_PROOF = BOARD / "v61_fast_stop_proof.csv"
STATUS = BOARD / "v61_hw_compare_status.txt"


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
        tail = value.split("'")[-1]
        base = tail[0]
        digits = tail[1:].replace("x", "0")
        if base == "h":
            return int(digits, 16)
        if base == "b":
            return int(digits, 2)
        if base == "d":
            return int(digits, 10)
    if value.startswith("0x"):
        return int(value, 16)
    if all(ch in "01" for ch in value) and len(value) > 8:
        return int(value, 2)
    return int(value, 16)


def find_column(header, token, required=True):
    matches = [i for i, name in enumerate(header) if token in name]
    if not matches:
        if required:
            raise SystemExit(f"missing column containing {token!r}")
        return None
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
    idx_done_mask = find_column(header, "verify_done_mask")
    idx_done_mask_next = find_column(header, "verify_done_mask_next")
    idx_fast_stop = find_column(header, "fast_stop_pulse_dbg")

    samples = []
    writes = []
    for row in rows[2:]:
        if len(row) < len(header):
            continue
        sample = int(row[idx_sample], 0)
        data_bus = parse_int(row[idx_data])
        we_mask = parse_int(row[idx_we])
        addr_bus = parse_int(row[idx_addr])
        cnt = parse_int(row[idx_cnt])
        done = parse_int(row[idx_done]) != 0
        done_mask = parse_int(row[idx_done_mask])
        done_mask_next = parse_int(row[idx_done_mask_next])
        fast_stop = parse_int(row[idx_fast_stop]) != 0
        sample_info = {
            "sample": sample,
            "cnt": cnt,
            "we_mask": we_mask,
            "addr_bus": addr_bus,
            "done": done,
            "done_mask": done_mask,
            "done_mask_next": done_mask_next,
            "fast_stop": fast_stop,
        }
        samples.append(sample_info)
        for core in range(16):
            if not (we_mask & (1 << core)):
                continue
            addr = (addr_bus >> (core * 5)) & 0x1F
            data = f"{(data_bus >> (core * 16)) & 0xFFFF:04x}"
            writes.append((sample, cnt, core, addr, data, we_mask, done, done_mask, done_mask_next, fast_stop))

    first_by_addr = {}
    for item in writes:
        first_by_addr.setdefault(item[3], item)

    compare_rows = [["addr", "captured_hex", "expected_hex", "cnt_test_at_write", "sample", "writer_core", "we_mask", "done", "status"]]
    compare_ok = True
    for addr in range(16):
        if addr not in first_by_addr:
            compare_rows.append([addr, "", expected[addr], "", "", "", "", "", "MISSING"])
            compare_ok = False
            continue
        sample, cnt, core, _, data, we_mask, done, *_ = first_by_addr[addr]
        status = "PASS" if data == expected[addr] else "FAIL"
        if status != "PASS":
            compare_ok = False
        compare_rows.append([addr, data, expected[addr], cnt, sample, core, f"0x{we_mask:04x}", int(done), status])

    with OUT_COMPARE.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(compare_rows)

    fast_stop_samples = [s for s in samples if s["fast_stop"]]
    first_fast_stop = fast_stop_samples[0] if fast_stop_samples else None
    done_samples = [s for s in samples if s["done"]]
    first_done = done_samples[0] if done_samples else None
    last_write = writes[-1] if writes else None
    writes_at_or_before_stop = 0
    unique_at_or_before_stop = set()
    if first_fast_stop is not None:
        for item in writes:
            if item[0] <= first_fast_stop["sample"]:
                writes_at_or_before_stop += 1
                unique_at_or_before_stop.add(item[3])

    last_write_addr = last_write[3] if last_write else None
    last_write_sample = last_write[0] if last_write else None
    last_write_cnt = last_write[1] if last_write else None
    first_stop_sample = first_fast_stop["sample"] if first_fast_stop else None
    first_stop_cnt = first_fast_stop["cnt"] if first_fast_stop else None
    first_stop_done_mask = first_fast_stop["done_mask"] if first_fast_stop else None
    first_stop_done_mask_next = first_fast_stop["done_mask_next"] if first_fast_stop else None
    first_stop_we_mask = first_fast_stop["we_mask"] if first_fast_stop else None
    first_done_sample = first_done["sample"] if first_done else None
    first_done_cnt = first_done["cnt"] if first_done else None

    fast_stop_not_early = (
        first_fast_stop is not None
        and len(writes) == 16
        and len(first_by_addr) == 16
        and last_write_addr == 15
        and last_write_sample <= first_stop_sample
        and writes_at_or_before_stop == 16
        and len(unique_at_or_before_stop) == 16
        and first_stop_done_mask_next == 0xFFFF
    )

    proof_rows = [
        ["metric", "value"],
        ["write_count", len(writes)],
        ["unique_addr_count", len(first_by_addr)],
        ["last_write_addr", last_write_addr],
        ["last_write_sample", last_write_sample],
        ["last_write_cnt_test", last_write_cnt],
        ["first_fast_stop_sample", first_stop_sample],
        ["first_fast_stop_cnt_test", first_stop_cnt],
        ["first_done_sample", first_done_sample],
        ["first_done_cnt_test", first_done_cnt],
        ["verify_we_at_first_fast_stop", f"0x{first_stop_we_mask:04x}" if first_stop_we_mask is not None else ""],
        ["writes_at_or_before_first_fast_stop", writes_at_or_before_stop],
        ["unique_addrs_at_or_before_first_fast_stop", len(unique_at_or_before_stop)],
        ["verify_done_mask_q_at_first_fast_stop", f"0x{first_stop_done_mask:04x}" if first_stop_done_mask is not None else ""],
        ["verify_done_mask_next_at_first_fast_stop", f"0x{first_stop_done_mask_next:04x}" if first_stop_done_mask_next is not None else ""],
        ["fast_stop_not_early", "PASS" if fast_stop_not_early else "FAIL"],
        ["compare_status", "PASS" if compare_ok else "FAIL"],
        ["overall_status", "PASS" if compare_ok and fast_stop_not_early else "FAIL"],
    ]
    with OUT_PROOF.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows(proof_rows)

    pass_status = compare_ok and fast_stop_not_early
    summary = [
        f"write_count={len(writes)}",
        f"unique_addr_count={len(first_by_addr)}",
        f"last_write_addr={last_write_addr}",
        f"last_write_sample={last_write_sample}",
        f"last_write_cnt_test={last_write_cnt}",
        f"first_fast_stop_sample={first_stop_sample}",
        f"first_fast_stop_cnt_test={first_stop_cnt}",
        f"first_done_sample={first_done_sample}",
        f"first_done_cnt_test={first_done_cnt}",
        f"verify_we_at_first_fast_stop=0x{first_stop_we_mask:04x}" if first_stop_we_mask is not None else "verify_we_at_first_fast_stop=",
        f"writes_at_or_before_first_fast_stop={writes_at_or_before_stop}",
        f"unique_addrs_at_or_before_first_fast_stop={len(unique_at_or_before_stop)}",
        f"verify_done_mask_q_at_first_fast_stop=0x{first_stop_done_mask:04x}" if first_stop_done_mask is not None else "verify_done_mask_q_at_first_fast_stop=",
        f"verify_done_mask_next_at_first_fast_stop=0x{first_stop_done_mask_next:04x}" if first_stop_done_mask_next is not None else "verify_done_mask_next_at_first_fast_stop=",
        f"fast_stop_not_early={'PASS' if fast_stop_not_early else 'FAIL'}",
        f"compare_status={'PASS' if compare_ok else 'FAIL'}",
        f"overall_status={'PASS' if pass_status else 'FAIL'}",
        "compare_csv=board_validation/v61_hw_compare.csv",
        "proof_csv=board_validation/v61_fast_stop_proof.csv",
    ]
    STATUS.write_text("\n".join(summary) + "\n", encoding="utf-8")
    print("\n".join(summary))
    if not pass_status:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
