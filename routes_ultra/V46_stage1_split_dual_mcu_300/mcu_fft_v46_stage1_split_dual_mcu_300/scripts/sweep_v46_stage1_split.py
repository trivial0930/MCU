#!/usr/bin/env python3
import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
    "tb/tb_mcu_fft8.v",
    "rtl/mcu_top.v",
    "rtl/mcu_core.v",
    "rtl/instr_rom.v",
    "rtl/data_ram.v",
    "rtl/shared_data_ram.v",
    "rtl/ext_test_rom_if.v",
    "rtl/verify_ram_if.v",
    "rtl/cnt_test.v",
    "rtl/decoder.v",
    "rtl/control_unit.v",
    "rtl/reg_file.v",
    "rtl/alu.v",
]
CORE1_VERIFY_ADDRS = {1, 3, 5, 7, 9, 11, 13, 15}
OPCODES = {
    "NOP": "0x0",
    "ADD": "0x1",
    "SUB": "0x2",
    "AND": "0x3",
    "OR": "0x4",
    "MOVI": "0x5",
    "MOVR": "0x6",
    "LDR": "0x7",
    "STR": "0x8",
    "B": "0x9",
    "BL": "0xa",
    "CMP": "0xb",
    "BEQ": "0xc",
    "BNE": "0xd",
    "MUL": "0xe",
    "HALT": "0xf",
}


def require_tool(name):
    if shutil.which(name) is None:
        raise SystemExit(f"missing required tool: {name}")


def run(cmd, *, env=None, check=True, capture=False):
    return subprocess.run(
        cmd,
        cwd=ROOT,
        env=env,
        check=check,
        text=True,
        capture_output=capture,
    )


def parse_int_list(text):
    values = []
    for part in text.split(","):
        part = part.strip()
        if not part:
            continue
        values.append(int(part, 0))
    return values


def prepare():
    require_tool("iverilog")
    require_tool("vvp")
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)
    py = sys.executable
    run([
        py,
        "scripts/official_fft_model.py",
        "emit",
        "--input-coe",
        "mem/FFT_input.coe",
        "--expected-coe",
        "mem/FFT_output.coe",
        "--mem",
        "mem/FFT_input.mem",
        "--expected",
        "results/expected_fft_output.txt",
    ])
    run([
        "iverilog",
        "-g2005",
        "-DTRACE_VERIFY",
        "-I",
        "rtl",
        "-I",
        "tb",
        "-o",
        "build/tb_v46_stage1_split_trace.vvp",
        *SOURCES,
    ])


def generate_programs(stage1_wait, stage2_wait, stage3_wait, final_delay):
    env = os.environ.copy()
    env["CORE1_WAIT_STAGE1_RAW_NOP"] = str(stage1_wait)
    env["CORE1_WAIT_STAGE2_NOP"] = str(stage2_wait)
    env["CORE1_WAIT_STAGE3_NOP"] = str(stage3_wait)
    env["CORE1_FINAL_ADDR15_DELAY_NOP"] = str(final_delay)
    py = sys.executable
    run([py, "scripts/gen_fft8_official_asm.py"], env=env, capture=True)
    run([py, "scripts/assembler.py", "asm/fft8_official_sample.asm", "-o", "mem/instr_fft8.mem", "--coe", "mem/instr_fft8.coe"], capture=True)
    run([py, "scripts/assembler.py", "asm/fft8_core1_output.asm", "-o", "mem/instr_core1.mem", "--coe", "mem/instr_core1.coe"], capture=True)


def simulate(test_mem, got_file):
    proc = run([
        "vvp",
        "build/tb_v46_stage1_split_trace.vvp",
        f"+TEST_MEM={test_mem}",
        f"+OUT_FILE={got_file}",
    ], check=False, capture=True)
    text = (proc.stdout or "") + (proc.stderr or "")
    writes = []
    for match in re.finditer(r"verify cycle=(\d+) addr=(\d+) data=([0-9a-fA-F]+)", text):
        writes.append({
            "cycle": int(match.group(1)),
            "addr": int(match.group(2)),
            "data": match.group(3).lower(),
        })
    done_match = re.search(r"done cycles=(\d+) cnt_test=(\d+)", text)
    cnt_test = int(done_match.group(2)) if done_match else ""
    return proc.returncode, writes, cnt_test, text


def check_output(expected, got):
    proc = run([
        sys.executable,
        "scripts/official_fft_model.py",
        "check",
        "--expected",
        expected,
        "--got",
        got,
    ], check=False, capture=True)
    return proc.returncode == 0


def structural_status(writes):
    addrs = [row["addr"] for row in writes]
    unique_ok = sorted(set(addrs)) == list(range(16))
    count_ok = len(writes) == 16
    last_addr = addrs[-1] if addrs else ""
    addr15_is_last = last_addr == 15
    return count_ok, unique_ok, last_addr, addr15_is_last


def run_random_suite(random_cases, seed):
    py = sys.executable
    for idx in range(random_cases):
        case_seed = seed + idx
        mem = f"build/random_{idx:03d}.mem"
        expected = f"results/random_{idx:03d}_expected.txt"
        got = f"results/random_{idx:03d}_got.txt"
        run([
            py,
            "scripts/official_fft_model.py",
            "random",
            "--template-coe",
            "mem/FFT_input.coe",
            "--seed",
            str(case_seed),
            "--mem",
            mem,
            "--expected",
            expected,
        ], capture=True)
        rc, writes, _, _ = simulate(mem, got)
        count_ok, unique_ok, last_addr, addr15_is_last = structural_status(writes)
        if rc != 0 or not count_ok or not unique_ok or not addr15_is_last:
            return False
        if not check_output(expected, got):
            return False
    return True


def write_verify_trace(writes, path):
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["write_order", "verify_addr", "captured_hex", "cycle", "writer_core"])
        writer.writeheader()
        for idx, row in enumerate(writes):
            writer.writerow({
                "write_order": idx,
                "verify_addr": row["addr"],
                "captured_hex": row["data"],
                "cycle": row["cycle"],
                "writer_core": "Core1" if row["addr"] in CORE1_VERIFY_ADDRS else "Core0",
            })


def write_opcode_summary(path):
    rows = []
    for core, asm in [("Core0", "asm/fft8_official_sample.asm"), ("Core1", "asm/fft8_core1_output.asm")]:
        counts = Counter()
        for raw in (ROOT / asm).read_text(encoding="utf-8").splitlines():
            line = raw.split(";", 1)[0].strip()
            if not line or line.lower().startswith(".equ"):
                continue
            while ":" in line:
                _, rest = line.split(":", 1)
                line = rest.strip()
                if not line:
                    break
            if not line:
                continue
            mnemonic = line.split(None, 1)[0].upper()
            if mnemonic in OPCODES:
                counts[mnemonic] += 1
        for mnemonic in sorted(counts, key=lambda item: int(OPCODES[item], 16)):
            rows.append({
                "core": core,
                "mnemonic": mnemonic,
                "opcode_hex": OPCODES[mnemonic],
                "count": counts[mnemonic],
                "is_fft_special": "no",
            })
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["core", "mnemonic", "opcode_hex", "count", "is_fft_special"])
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage1-wait", type=int, default=12)
    parser.add_argument("--stage2-waits", default="0,30,35,40,45,50,55,60,65,68")
    parser.add_argument("--stage3-wait", type=int, default=0)
    parser.add_argument("--final-delays", default="0,3,6,9,12,15,18,21,24")
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()

    prepare()
    rows = []
    best = None

    for stage2_wait in parse_int_list(args.stage2_waits):
        for final_delay in parse_int_list(args.final_delays):
            generate_programs(args.stage1_wait, stage2_wait, args.stage3_wait, final_delay)
            got = f"results/v46_stage2_{stage2_wait:03d}_delay_{final_delay:02d}_got.txt"
            rc, writes, cnt_test, _ = simulate("mem/FFT_input.mem", got)
            count_ok, unique_ok, last_addr, addr15_is_last = structural_status(writes)
            official_pass = rc == 0 and count_ok and unique_ok and check_output("results/expected_fft_output.txt", got)
            random_pass = ""
            last_writer = "Core1" if last_addr in CORE1_VERIFY_ADDRS else ("Core0" if last_addr != "" else "")

            if not official_pass:
                conclusion = "REJECT_OFFICIAL_OR_TRACE"
            elif not addr15_is_last:
                conclusion = "REJECT_ADDR15_EARLY_FALSE_STOP"
            else:
                random_ok = run_random_suite(args.random_cases, args.seed)
                random_pass = "yes" if random_ok else "no"
                if random_ok:
                    conclusion = "ACCEPTED_NO_SPEED_GAIN" if int(cnt_test) >= 85 else "ACCEPTED_SPEED_GAIN"
                    candidate = {
                        "cnt_test": int(cnt_test),
                        "stage2_wait": stage2_wait,
                        "final_delay": final_delay,
                        "writes": writes,
                    }
                    if best is None or candidate["cnt_test"] < best["cnt_test"]:
                        best = candidate
                else:
                    conclusion = "REJECT_RANDOM_FAIL"

            row = {
                "stage2_wait": stage2_wait,
                "final_addr15_delay": final_delay,
                "official_pass": "yes" if official_pass else "no",
                "random_pass": random_pass,
                "cnt_test": cnt_test,
                "verify_write_count": len(writes),
                "last_verify_addr": last_addr,
                "last_writer_core": last_writer,
                "addr15_is_last": "yes" if addr15_is_last else "no",
                "conclusion": conclusion,
            }
            rows.append(row)
            print(
                f"wait={stage2_wait:2d} final={final_delay:2d} "
                f"official={row['official_pass']} random={row['random_pass']} "
                f"cnt={cnt_test} last={last_addr} {conclusion}"
            )

    out_csv = ROOT / "results" / "v46_stage1_split_sweep.csv"
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    if best is not None:
        generate_programs(args.stage1_wait, best["stage2_wait"], args.stage3_wait, best["final_delay"])
        rc, writes, cnt_test, _ = simulate("mem/FFT_input.mem", "results/verify_output.txt")
        write_verify_trace(writes, ROOT / "results" / "verify_write_trace.csv")
        write_opcode_summary(ROOT / "results" / "opcode_summary.csv")
        summary = (
            f"stage1_raw_wait={args.stage1_wait}\n"
            f"stage2_wait={best['stage2_wait']}\n"
            f"stage3_wait={args.stage3_wait}\n"
            f"final_addr15_delay={best['final_delay']}\n"
            f"cnt_test={cnt_test}\n"
            f"conclusion={'NO_SPEED_GAIN' if int(cnt_test) >= 85 else 'SPEED_GAIN'}\n"
        )
        (ROOT / "results" / "v46_best_summary.txt").write_text(summary, encoding="utf-8")
    else:
        (ROOT / "results" / "v46_best_summary.txt").write_text("no accepted candidate\n", encoding="utf-8")

    print(f"wrote {out_csv}")


if __name__ == "__main__":
    main()
