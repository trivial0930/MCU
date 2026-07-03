#!/usr/bin/env python3
import argparse
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

ROUTES = [
    ("speed_v6_official_sample", ROOT / "speed_v6_official_sample" / "mcu_fft_official_sample"),
    ("speed_v7_q7_narrow_mul", ROOT / "speed_v7_q7_narrow_mul" / "mcu_fft_q7_narrow_mul"),
    ("speed_v7b_c91_shift_add", ROOT / "speed_v7b_c91_shift_add" / "mcu_fft_c91_shift_add"),
    ("speed_v7c_c91_shift_sub", ROOT / "speed_v7c_c91_shift_sub" / "mcu_fft_c91_shift_sub"),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()

    missing = [tool for tool in ("iverilog", "vvp") if shutil.which(tool) is None]
    if missing:
        raise SystemExit(
            "missing simulation tool(s): "
            + ", ".join(missing)
            + "\nInstall Icarus Verilog or run this regression on a machine where "
              "`iverilog` and `vvp` are available in PATH. No route logs were updated."
        )

    failed = []
    for name, path in ROUTES:
        log = path / "results" / "route_a_regression.log"
        log.parent.mkdir(parents=True, exist_ok=True)
        cmd = [
            sys.executable,
            "scripts/run_official_regression.py",
            "--random-cases",
            str(args.random_cases),
            "--seed",
            str(args.seed),
        ]
        print(f"{name}: running {args.random_cases} random cases")
        with log.open("w", encoding="utf-8") as fh:
            proc = subprocess.run(cmd, cwd=path, stdout=fh, stderr=subprocess.STDOUT, text=True)
        if proc.returncode == 0:
            print(f"{name}: PASS ({log})")
        else:
            print(f"{name}: FAIL ({log})")
            failed.append(name)

    if failed:
        raise SystemExit("failed routes: " + ", ".join(failed))
    print("route A local regressions PASS")


if __name__ == "__main__":
    main()
