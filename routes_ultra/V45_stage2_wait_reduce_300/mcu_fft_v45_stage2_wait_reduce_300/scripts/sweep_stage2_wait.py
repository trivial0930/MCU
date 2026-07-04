#!/usr/bin/env python3
import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
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


def prepare_trace_build():
    py = sys.executable
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)
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
        "build/tb_mcu_fft8_trace.vvp",
        *SOURCES,
    ])


def generate_programs(stage2_wait, stage3_wait, final_addr15_delay):
    env = os.environ.copy()
    env["CORE1_WAIT_STAGE2_NOP"] = str(stage2_wait)
    env["CORE1_WAIT_STAGE3_NOP"] = str(stage3_wait)
    env["CORE1_FINAL_ADDR15_DELAY_NOP"] = str(final_addr15_delay)
    py = sys.executable
    run([py, "scripts/gen_fft8_official_asm.py"], env=env)
    run([py, "scripts/assembler.py", "asm/fft8_official_sample.asm", "-o", "mem/instr_fft8.mem", "--coe", "mem/instr_fft8.coe"])
    run([py, "scripts/assembler.py", "asm/fft8_core1_output.asm", "-o", "mem/instr_core1.mem", "--coe", "mem/instr_core1.coe"])


def simulate_and_check(stage2_wait, final_addr15_delay):
    got = f"results/sweep_stage2_{stage2_wait:03d}_delay_{final_addr15_delay:02d}_got.txt"
    proc = run([
        "vvp",
        "build/tb_mcu_fft8_trace.vvp",
        "+TEST_MEM=mem/FFT_input.mem",
        f"+OUT_FILE={got}",
    ], check=False, capture=True)

    text = (proc.stdout or "") + (proc.stderr or "")
    verify = []
    for match in re.finditer(r"verify cycle=(\d+) addr=(\d+) data=([0-9a-fA-F]+)", text):
        verify.append((int(match.group(1)), int(match.group(2)), match.group(3).lower()))

    done_cycles = ""
    cnt_test = ""
    done_match = re.search(r"done cycles=(\d+) cnt_test=(\d+)", text)
    if done_match:
        done_cycles = int(done_match.group(1))
        cnt_test = int(done_match.group(2))

    check = run([
        sys.executable,
        "scripts/official_fft_model.py",
        "check",
        "--expected",
        "results/expected_fft_output.txt",
        "--got",
        got,
    ], check=False, capture=True)

    addresses = [addr for _, addr, _ in verify]
    unique_addresses = sorted(set(addresses))
    last_addr = addresses[-1] if addresses else ""
    safe = (
        proc.returncode == 0
        and check.returncode == 0
        and len(verify) == 16
        and unique_addresses == list(range(16))
        and last_addr == 15
    )
    if proc.returncode != 0:
        status = "sim_failed"
    elif check.returncode != 0:
        status = "mismatch"
    elif len(verify) != 16:
        status = f"bad_verify_count_{len(verify)}"
    elif unique_addresses != list(range(16)):
        status = "bad_address_coverage"
    elif last_addr != 15:
        status = f"addr15_not_last_last_{last_addr}"
    else:
        status = "safe"

    return {
        "stage2_wait": stage2_wait,
        "final_addr15_delay": final_addr15_delay,
        "status": status,
        "safe": "yes" if safe else "no",
        "done_cycles": done_cycles,
        "cnt_test": cnt_test,
        "verify_count": len(verify),
        "last_addr": last_addr,
        "last_verify_cycle": verify[-1][0] if verify else "",
        "vvp_returncode": proc.returncode,
        "check_returncode": check.returncode,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--min", dest="min_wait", type=int, default=40)
    parser.add_argument("--max", dest="max_wait", type=int, default=80)
    parser.add_argument("--stage3-wait", type=int, default=23)
    parser.add_argument("--final-delay-min", type=int, default=0)
    parser.add_argument("--final-delay-max", type=int, default=0)
    args = parser.parse_args()

    require_tool("iverilog")
    require_tool("vvp")
    prepare_trace_build()

    rows = []
    for wait in range(args.min_wait, args.max_wait + 1):
        for delay in range(args.final_delay_min, args.final_delay_max + 1):
            generate_programs(wait, args.stage3_wait, delay)
            row = simulate_and_check(wait, delay)
            rows.append(row)
            print(
                f"wait={wait:3d} delay={delay:2d} status={row['status']} "
                f"cnt={row['cnt_test']} verify={row['verify_count']} last_addr={row['last_addr']}"
            )

    out_csv = ROOT / "results" / "sweep_stage2_wait.csv"
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    safe_rows = [row for row in rows if row["safe"] == "yes"]
    summary = ROOT / "results" / "sweep_stage2_wait_summary.txt"
    with summary.open("w", encoding="utf-8") as f:
        f.write(f"stage3_wait={args.stage3_wait}\n")
        f.write(f"scanned={args.min_wait}..{args.max_wait}\n")
        f.write(f"final_addr15_delay={args.final_delay_min}..{args.final_delay_max}\n")
        if safe_rows:
            best = min(safe_rows, key=lambda row: int(row["cnt_test"]))
            f.write(f"min_safe_stage2_wait={best['stage2_wait']}\n")
            f.write(f"best_final_addr15_delay={best['final_addr15_delay']}\n")
            f.write(f"cnt_test={best['cnt_test']}\n")
            f.write(f"last_verify_cycle={best['last_verify_cycle']}\n")
        else:
            f.write("min_safe_stage2_wait=none\n")

    print(f"wrote {out_csv}")
    print(f"wrote {summary}")


if __name__ == "__main__":
    main()
