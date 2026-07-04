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


def run(cmd, **kwargs):
    return subprocess.run(cmd, cwd=ROOT, text=True, **kwargs)


def require_tool(name):
    if shutil.which(name) is None:
        raise SystemExit(f"missing required tool: {name}")


def parse_cnt(text):
    match = re.search(r"cnt_test=(\d+)", text)
    return int(match.group(1)) if match else None


def prepare(env):
    py = sys.executable
    for cmd in [
        [py, "scripts/gen_fft8_official_asm.py"],
        [py, "scripts/official_fft_model.py", "emit",
         "--input-coe", "mem/FFT_input.coe",
         "--expected-coe", "mem/FFT_output.coe",
         "--mem", "mem/FFT_input.mem",
         "--expected", "results/expected_fft_output.txt"],
        [py, "scripts/assembler.py", "asm/fft8_official_sample.asm",
         "-o", "mem/instr_fft8.mem", "--coe", "mem/instr_fft8.coe"],
        [py, "scripts/assembler.py", "asm/fft8_core1_output.asm",
         "-o", "mem/instr_core1.mem", "--coe", "mem/instr_core1.coe"],
        [py, "scripts/assembler.py", "asm/fft8_core2_output.asm",
         "-o", "mem/instr_core2.mem", "--coe", "mem/instr_core2.coe"],
        [py, "scripts/assembler.py", "asm/fft8_core3_output.asm",
         "-o", "mem/instr_core3.mem", "--coe", "mem/instr_core3.coe"],
    ]:
        proc = run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if proc.returncode != 0:
            return False, proc.stdout

    sources = [
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
    proc = run(["iverilog", "-g2005", "-I", "rtl", "-I", "tb",
                "-o", "build/tb_mcu_fft8.vvp", *sources],
               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return proc.returncode == 0, proc.stdout


def sim_and_check(tag, test_mem, expected, got, trace=False):
    py = sys.executable
    cmd = ["vvp", "build/tb_mcu_fft8.vvp", f"+TEST_MEM={test_mem}", f"+OUT_FILE={got}"]
    if trace:
        cmd += [
            "+VERIFY_TRACE=results/verify_writer_trace.csv",
            "+INPUT_TRACE=results/input_read_trace.csv",
        ]
    proc = run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if proc.returncode != 0:
        return False, parse_cnt(proc.stdout), proc.stdout
    cnt = parse_cnt(proc.stdout)
    chk = run([py, "scripts/official_fft_model.py", "check",
               "--expected", expected, "--got", got],
              stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return chk.returncode == 0, cnt, proc.stdout + chk.stdout


def trace_ok(path):
    rows = list(csv.DictReader(Path(path).open("r", encoding="utf-8")))
    if len(rows) != 16:
        return False, len(rows), "", ""
    last = rows[-1]
    return (
        last["is_last_write"] == "1",
        len(rows),
        last["verify_addr"],
        last["writer_core"],
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--core1-stage2", default="60,64,68,72")
    parser.add_argument("--core1-stage3", default="18,20,22,23,24,26")
    parser.add_argument("--core2-stage3", default="84,88,92,96,100,104")
    parser.add_argument("--core3-stage3", default="88,90,92,94,96,100")
    args = parser.parse_args()

    require_tool("iverilog")
    require_tool("vvp")
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)

    py = sys.executable
    out_csv = ROOT / "results" / "v53_quad_wait_sweep.csv"
    best = None
    fields = [
        "core1_stage2_wait",
        "core1_stage3_wait",
        "core2_stage3_wait",
        "core3_stage3_wait",
        "official_pass",
        "random_pass",
        "cnt_test",
        "verify_write_count",
        "last_verify_addr",
        "last_writer_core",
        "conclusion",
    ]

    def ints(text):
        return [int(x) for x in text.split(",") if x.strip()]

    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for c1s2 in ints(args.core1_stage2):
            for c1s3 in ints(args.core1_stage3):
                for c2s3 in ints(args.core2_stage3):
                    for c3s3 in ints(args.core3_stage3):
                        env = os.environ.copy()
                        env["CORE1_WAIT_STAGE2_NOP"] = str(c1s2)
                        env["CORE1_WAIT_STAGE3_NOP"] = str(c1s3)
                        env["CORE2_WAIT_STAGE3_NOP"] = str(c2s3)
                        env["CORE3_WAIT_STAGE3_NOP"] = str(c3s3)
                        ok, log = prepare(env)
                        row = {
                            "core1_stage2_wait": c1s2,
                            "core1_stage3_wait": c1s3,
                            "core2_stage3_wait": c2s3,
                            "core3_stage3_wait": c3s3,
                            "official_pass": "NO",
                            "random_pass": "NO",
                            "cnt_test": "",
                            "verify_write_count": "",
                            "last_verify_addr": "",
                            "last_writer_core": "",
                            "conclusion": "BUILD_FAIL" if not ok else "",
                        }
                        if ok:
                            official_ok, cnt, _ = sim_and_check(
                                "official",
                                "mem/FFT_input.mem",
                                "results/expected_fft_output.txt",
                                "results/v53_sweep_got.txt",
                                trace=True,
                            )
                            trace_pass, write_count, last_addr, last_writer = trace_ok(ROOT / "results" / "verify_writer_trace.csv")
                            row.update({
                                "official_pass": "YES" if official_ok and trace_pass else "NO",
                                "cnt_test": cnt if cnt is not None else "",
                                "verify_write_count": write_count,
                                "last_verify_addr": last_addr,
                                "last_writer_core": last_writer,
                            })
                            if official_ok and trace_pass:
                                random_ok = True
                                for i in range(args.random_cases):
                                    seed = args.seed + i
                                    mem = f"build/random_{i:03d}.mem"
                                    expected = f"results/random_{i:03d}_expected.txt"
                                    got = f"results/random_{i:03d}_got.txt"
                                    proc = run([py, "scripts/official_fft_model.py", "random",
                                                "--template-coe", "mem/FFT_input.coe",
                                                "--seed", str(seed),
                                                "--mem", mem,
                                                "--expected", expected],
                                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                                    if proc.returncode != 0:
                                        random_ok = False
                                        break
                                    ok_one, _, _ = sim_and_check("random", mem, expected, got)
                                    if not ok_one:
                                        random_ok = False
                                        break
                                row["random_pass"] = "YES" if random_ok else "NO"
                                if random_ok:
                                    if cnt < 85:
                                        row["conclusion"] = "PASS_BEATS_V45"
                                    else:
                                        row["conclusion"] = "PASS_NOT_FASTER"
                                    if best is None or cnt < best["cnt_test"]:
                                        best = {
                                            "cnt_test": cnt,
                                            "core1_stage2_wait": c1s2,
                                            "core1_stage3_wait": c1s3,
                                            "core2_stage3_wait": c2s3,
                                            "core3_stage3_wait": c3s3,
                                        }
                                else:
                                    row["conclusion"] = "RANDOM_FAIL"
                            else:
                                row["conclusion"] = "OFFICIAL_OR_TRACE_FAIL"
                        writer.writerow(row)
                        f.flush()
                        print(row)

    if best:
        (ROOT / "results" / "v53_best_summary.txt").write_text(
            "\n".join(f"{k}={v}" for k, v in best.items()) + "\n",
            encoding="utf-8",
        )
        print("best", best)
    else:
        print("no valid V53 candidate")


if __name__ == "__main__":
    main()
