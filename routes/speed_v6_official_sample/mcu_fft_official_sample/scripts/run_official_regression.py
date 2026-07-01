#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run(cmd, **kwargs):
    print("+", " ".join(str(x) for x in cmd))
    return subprocess.run(cmd, cwd=ROOT, check=True, text=True, **kwargs)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()

    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)

    py = sys.executable
    run([py, "scripts/gen_fft8_official_asm.py"])
    run([py, "scripts/official_fft_model.py", "emit",
         "--input-coe", "mem/FFT_input.coe",
         "--expected-coe", "mem/FFT_output.coe",
         "--mem", "mem/FFT_input.mem",
         "--expected", "results/expected_fft_output.txt"])
    run([py, "scripts/assembler.py", "asm/fft8_official_sample.asm",
         "-o", "mem/instr_fft8.mem", "--coe", "mem/instr_fft8.coe"])

    sources = [
        "tb/tb_mcu_fft8.v",
        "rtl/mcu_top.v",
        "rtl/mcu_core.v",
        "rtl/instr_rom.v",
        "rtl/data_ram.v",
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

    checks = []
    run(["vvp", "build/tb_mcu_fft8.vvp",
         "+TEST_MEM=mem/FFT_input.mem",
         "+OUT_FILE=results/verify_output.txt"])
    run([py, "scripts/official_fft_model.py", "check",
         "--expected", "results/expected_fft_output.txt",
         "--got", "results/verify_output.txt"])
    checks.append("official_sample PASS")

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
        run(["vvp", "build/tb_mcu_fft8.vvp",
             f"+TEST_MEM={mem}",
             f"+OUT_FILE={got}"])
        run([py, "scripts/official_fft_model.py", "check",
             "--expected", expected,
             "--got", got])
        checks.append(f"random_seed_{seed} PASS")

    summary = ROOT / "results" / "regression_summary.txt"
    summary.write_text("\n".join(checks) + "\n", encoding="utf-8")
    print(f"wrote {summary}")


if __name__ == "__main__":
    main()
