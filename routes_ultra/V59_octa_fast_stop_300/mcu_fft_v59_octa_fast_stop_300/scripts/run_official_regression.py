#!/usr/bin/env python3
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require_tool(name):
    if shutil.which(name) is None:
        raise SystemExit(f"missing required tool: {name}")


def run(cmd, **kwargs):
    print("+", " ".join(str(x) for x in cmd))
    return subprocess.run(cmd, cwd=ROOT, check=True, text=True, **kwargs)


def parse_cnt(output):
    match = re.search(r"cnt_test=(\d+)", output)
    if not match:
        raise RuntimeError("simulation output did not contain cnt_test")
    return int(match.group(1))


def build():
    py = sys.executable
    run([py, "scripts/gen_fft8_official_asm.py"])
    run([py, "scripts/official_fft_model.py", "emit",
         "--input-coe", "mem/FFT_input.coe",
         "--expected-coe", "mem/FFT_output.coe",
         "--mem", "mem/FFT_input.mem",
         "--expected", "results/expected_fft_output.txt"])

    asm_entries = [("core0", "asm/fft8_official_sample.asm", "mem/instr_fft8.mem", "mem/instr_fft8.coe")]
    asm_entries += [
        (f"core{i}", f"asm/fft8_core{i}_output.asm", f"mem/instr_core{i}.mem", f"mem/instr_core{i}.coe")
        for i in range(1, 8)
    ]
    for core, asm, mem, coe in asm_entries:
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
    args = parser.parse_args()

    require_tool("iverilog")
    require_tool("vvp")

    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)

    py = sys.executable
    build()

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
