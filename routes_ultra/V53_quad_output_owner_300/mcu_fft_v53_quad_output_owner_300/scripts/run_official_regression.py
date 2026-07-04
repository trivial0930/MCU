#!/usr/bin/env python3
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require_tool(name):
    if shutil.which(name) is None:
        raise SystemExit(
            f"missing required tool: {name}\n"
            "Install Icarus Verilog or add it to PATH before running this regression."
        )


def run(cmd, **kwargs):
    print("+", " ".join(str(x) for x in cmd))
    return subprocess.run(cmd, cwd=ROOT, check=True, text=True, **kwargs)


def parse_cnt(output):
    match = re.search(r"cnt_test=(\d+)", output)
    if not match:
        raise RuntimeError("simulation output did not contain cnt_test")
    return int(match.group(1))


def build(env=None):
    py = sys.executable
    run([py, "scripts/gen_fft8_official_asm.py"], env=env)
    run([py, "scripts/official_fft_model.py", "emit",
         "--input-coe", "mem/FFT_input.coe",
         "--expected-coe", "mem/FFT_output.coe",
         "--mem", "mem/FFT_input.mem",
         "--expected", "results/expected_fft_output.txt"])
    for core, asm, mem, coe in [
        ("core0", "asm/fft8_official_sample.asm", "mem/instr_fft8.mem", "mem/instr_fft8.coe"),
        ("core1", "asm/fft8_core1_output.asm", "mem/instr_core1.mem", "mem/instr_core1.coe"),
        ("core2", "asm/fft8_core2_output.asm", "mem/instr_core2.mem", "mem/instr_core2.coe"),
        ("core3", "asm/fft8_core3_output.asm", "mem/instr_core3.mem", "mem/instr_core3.coe"),
    ]:
        print(f"assembling {core}")
        run([py, "scripts/assembler.py", asm, "-o", mem, "--coe", coe])

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
    run(["iverilog", "-g2005", "-I", "rtl", "-I", "tb",
         "-o", "build/tb_mcu_fft8.vvp", *sources])


def simulate(test_mem, out_file, verify_trace=None, input_trace=None):
    cmd = ["vvp", "build/tb_mcu_fft8.vvp",
           f"+TEST_MEM={test_mem}",
           f"+OUT_FILE={out_file}"]
    if verify_trace:
        cmd.append(f"+VERIFY_TRACE={verify_trace}")
    if input_trace:
        cmd.append(f"+INPUT_TRACE={input_trace}")
    proc = run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(proc.stdout)
    return parse_cnt(proc.stdout)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--core1-wait", type=int)
    parser.add_argument("--core2-wait", type=int)
    parser.add_argument("--core3-wait", type=int)
    args = parser.parse_args()

    require_tool("iverilog")
    require_tool("vvp")

    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)

    env = os.environ.copy()
    if args.core1_wait is not None:
        env["CORE1_WAIT_STAGE2_NOP"] = str(args.core1_wait)
    if args.core2_wait is not None:
        env["CORE2_WAIT_STAGE3_NOP"] = str(args.core2_wait)
    if args.core3_wait is not None:
        env["CORE3_WAIT_STAGE3_NOP"] = str(args.core3_wait)

    py = sys.executable
    build(env=env)

    checks = []
    cnt = simulate(
        "mem/FFT_input.mem",
        "results/verify_output.txt",
        "results/verify_writer_trace.csv",
        "results/input_read_trace.csv",
    )
    run([py, "scripts/official_fft_model.py", "check",
         "--expected", "results/expected_fft_output.txt",
         "--got", "results/verify_output.txt"])
    checks.append(f"official_sample PASS cnt_test={cnt}")

    for i in range(args.random_cases):
        seed = args.seed + i
        mem = f"build/random_{i:03d}.mem"
        expected = f"results/random_{i:03d}_expected.txt"
        got = f"results/random_{i:03d}_got.txt"
        run([py, "scripts/official_fft_model.py", "random",
             "--template-coe", "mem/FFT_input.coe",
             "--seed", str(seed),
             "--mem", mem,
             "--expected", expected])
        rnd_cnt = simulate(mem, got)
        run([py, "scripts/official_fft_model.py", "check",
             "--expected", expected,
             "--got", got])
        checks.append(f"random_seed_{seed} PASS cnt_test={rnd_cnt}")

    summary = ROOT / "results" / "regression_summary.txt"
    summary.write_text("\n".join(checks) + "\n", encoding="utf-8")
    print(f"wrote {summary}")


if __name__ == "__main__":
    main()
