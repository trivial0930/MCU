#!/usr/bin/env python3
import argparse
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

ROUTES = [
    ("B1_full_fusion", ROOT / "B1_full_fusion" / "mcu_fft_b1_full_fusion"),
    ("B2_w1_only_fusion", ROOT / "B2_w1_only_fusion" / "mcu_fft_b2_w1_only_fusion"),
    ("B3_w3_only_fusion", ROOT / "B3_w3_only_fusion" / "mcu_fft_b3_w3_only_fusion"),
    ("B4_schedule_only", ROOT / "B4_schedule_only" / "mcu_fft_b4_schedule_only"),
]


def require_tool(name):
    if shutil.which(name) is None:
        raise SystemExit(
            f"missing simulation tool: {name}\n"
            "请先安装 Icarus Verilog，或把 iverilog/vvp 所在目录加入 PATH。"
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--random-cases", type=int, default=20)
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()

    require_tool("iverilog")
    require_tool("vvp")

    failed = []
    for name, path in ROUTES:
        log = path / "results" / "routesB_regression.log"
        log.parent.mkdir(parents=True, exist_ok=True)
        cmd = [
            sys.executable,
            "scripts/run_official_regression.py",
            "--random-cases",
            str(args.random_cases),
            "--seed",
            str(args.seed),
        ]
        print(f"{name}: running official sample + {args.random_cases} random cases")
        with log.open("w", encoding="utf-8") as fh:
            proc = subprocess.run(cmd, cwd=path, stdout=fh, stderr=subprocess.STDOUT, text=True)
        if proc.returncode == 0:
            print(f"{name}: PASS ({log})")
        else:
            print(f"{name}: FAIL ({log})")
            failed.append(name)

    if failed:
        raise SystemExit("failed route B plans: " + ", ".join(failed))
    print("routesB regressions PASS")


if __name__ == "__main__":
    main()
