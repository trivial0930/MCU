import argparse
import csv
import os
import re
import shutil
import stat
import subprocess
import time
from pathlib import Path


ROUTE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROUTE_ROOT.parents[2]
RESULTS_DIR = ROUTE_ROOT / "results"
INPUT_CLK_MHZ = 50.0
CNT_TEST = 88

SWEEP_POINTS = [
    {"label": "300", "requested": 300.0, "mult": 30, "out_div": 5, "divclk": 1},
    {"label": "320", "requested": 320.0, "mult": 32, "out_div": 5, "divclk": 1},
    {"label": "333", "requested": 333.0, "mult": 20, "out_div": 3, "divclk": 1},
    {"label": "340", "requested": 340.0, "mult": 34, "out_div": 5, "divclk": 1},
    {"label": "350", "requested": 350.0, "mult": 28, "out_div": 4, "divclk": 1},
    {"label": "360", "requested": 360.0, "mult": 36, "out_div": 5, "divclk": 1},
]


def pll_freq(point):
    vco = INPUT_CLK_MHZ * point["mult"] / point["divclk"]
    freq = vco / point["out_div"]
    return vco, freq


def read_text(path):
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except FileNotFoundError:
        return ""


def parse_timing(path):
    text = read_text(path)
    metrics = {"WNS": "", "TNS": "", "WHS": "", "THS": ""}
    match = re.search(
        r"\n\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+\d+\s+\d+\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+",
        text,
    )
    if match:
        metrics.update({
            "WNS": match.group(1),
            "TNS": match.group(2),
            "WHS": match.group(3),
            "THS": match.group(4),
        })
    return metrics


def parse_util(path):
    text = read_text(path)
    metrics = {"LUT": "", "FF": "", "BRAM": "", "DSP": ""}
    patterns = {
        "LUT": r"\|\s*Slice LUTs\s*\|\s*(\d+)\s*\|",
        "FF": r"\|\s*Slice Registers\s*\|\s*(\d+)\s*\|",
        "BRAM": r"\|\s*Block RAM Tile\s*\|\s*(\d+)\s*\|",
        "DSP": r"\|\s*DSPs\s*\|\s*(\d+)\s*\|",
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, text)
        if match:
            metrics[key] = match.group(1)
    return metrics


def parse_status(path):
    text = read_text(path)
    status = ""
    notes = ""
    for line in text.splitlines():
        if line.startswith("status="):
            status = line.split("=", 1)[1].strip()
        if line.startswith("notes="):
            notes = line.split("=", 1)[1].strip()
    return status, notes


def safe_rmtree(path):
    if not path.exists():
        return
    root = ROUTE_ROOT.resolve()
    target = path.resolve()
    if target != root and root not in target.parents:
        raise RuntimeError(f"refuse to delete outside route root: {target}")

    def onerror(func, error_path, _exc_info):
        try:
            os.chmod(error_path, stat.S_IWRITE)
        except OSError:
            pass
        func(error_path)

    last_error = None
    for _ in range(3):
        try:
            shutil.rmtree(path, onerror=onerror)
            return
        except PermissionError as exc:
            last_error = exc
            time.sleep(1)
    raise last_error


def write_tcl(point, out_dir, tcl_path):
    defines = (
        f"{{PLL_DIVCLK_DIVIDE={point['divclk']} "
        f"PLL_CLKFBOUT_MULT={point['mult']} "
        f"PLL_CLKOUT0_DIVIDE={point['out_div']}}}"
    )
    script = f"""
set ENABLE_ILA 0
set PART_NAME xc7k160tffg676-2
set TARGET_PERIOD_NS 20.000
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0
set JOBS 4
set OUT_DIR {{{out_dir.as_posix()}}}
set EXTRA_VERILOG_DEFINES {defines}
source [file normalize [file join [pwd] .. .. vivado run_no_ila_board_bitstream.tcl]]
"""
    tcl_path.write_text(script.lstrip(), encoding="utf-8")


def run_vivado(point, vivado):
    label = point["label"]
    sweep_build = ROUTE_ROOT / "build" / "freq_sweep"
    sweep_build.mkdir(parents=True, exist_ok=True)
    out_dir = Path("D:/vivado_work/routes_ultra") / f"mcu_fft_v43_freq_{label}"
    tcl_path = sweep_build / f"freq_{label}.tcl"
    write_tcl(point, out_dir, tcl_path)

    freq_results = RESULTS_DIR / f"freq_{label}"
    safe_rmtree(freq_results)

    common_results = RESULTS_DIR / "vivado_board"
    safe_rmtree(common_results)

    cmd = [vivado, "-mode", "batch", "-source", str(tcl_path)]
    proc = subprocess.run(cmd, cwd=ROUTE_ROOT, text=True)

    if common_results.exists():
        shutil.move(str(common_results), str(freq_results))

    status_file = freq_results / "board_bitstream_status.txt"
    status, notes = parse_status(status_file)
    timing = parse_timing(freq_results / "board_timing_summary.rpt")
    util = parse_util(freq_results / "board_utilization.rpt")
    ok = proc.returncode == 0 and status == "ok"
    return ok, status, notes, timing, util


def result_row(point, vivado=None, skip_build=False):
    vco, freq = pll_freq(point)
    period = 1000.0 / freq
    base = {
        "freq_mhz": f"{freq:.3f}",
        "requested_mhz": f"{point['requested']:.3f}",
        "pll_vco_mhz": f"{vco:.3f}",
        "pll_mult": point["mult"],
        "pll_out_div": point["out_div"],
        "clk_period_ns": f"{period:.3f}",
        "bitstream_generated": "no",
        "WNS": "",
        "TNS": "",
        "WHS": "",
        "THS": "",
        "LUT": "",
        "FF": "",
        "DSP": "",
        "BRAM": "",
        "cnt_test": CNT_TEST,
        "theoretical_time_us": f"{CNT_TEST / freq:.6f}",
        "conclusion": "",
    }

    if vco < 800.0 or vco > 1600.0:
        base["conclusion"] = f"blocked_plle2_vco_range_{vco:.1f}MHz"
        return base

    if skip_build:
        freq_results = RESULTS_DIR / f"freq_{point['label']}"
        status, _notes = parse_status(freq_results / "board_bitstream_status.txt")
        timing = parse_timing(freq_results / "board_timing_summary.rpt")
        util = parse_util(freq_results / "board_utilization.rpt")
        if status == "ok" and timing.get("WNS"):
            base.update(timing)
            base.update(util)
            base["bitstream_generated"] = "yes"
            if float(base["WNS"]) >= 0.0 and base.get("DSP") == "0":
                base["conclusion"] = "timing_clean_dsp0"
            elif base.get("DSP") != "0":
                base["conclusion"] = "invalid_dsp_used"
            else:
                base["conclusion"] = "timing_failed_bitstream_generated_dsp0"
            return base
        base["conclusion"] = "skipped_by_filter"
        return base

    ok, status, notes, timing, util = run_vivado(point, vivado)
    base.update(timing)
    base.update(util)
    base["bitstream_generated"] = "yes" if ok else "no"
    if ok and timing.get("WNS") and float(timing["WNS"]) >= 0.0 and util.get("DSP") == "0":
        base["conclusion"] = "timing_clean_dsp0"
    elif ok and util.get("DSP") == "0" and timing.get("WNS"):
        base["conclusion"] = "timing_failed_bitstream_generated_dsp0"
    elif ok and util.get("DSP") != "0":
        base["conclusion"] = "invalid_dsp_used"
    else:
        base["conclusion"] = f"failed_or_timing_negative_status_{status}_{notes[:80]}".strip()
    return base


def write_csv(rows):
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    csv_path = RESULTS_DIR / "freq_sweep.csv"
    fieldnames = [
        "requested_mhz",
        "freq_mhz",
        "pll_vco_mhz",
        "pll_mult",
        "pll_out_div",
        "clk_period_ns",
        "bitstream_generated",
        "WNS",
        "TNS",
        "WHS",
        "THS",
        "LUT",
        "FF",
        "DSP",
        "BRAM",
        "cnt_test",
        "theoretical_time_us",
        "conclusion",
    ]
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return csv_path


def write_report(rows):
    lines = [
        "# V43 高频扫频报告",
        "",
        "本报告基于 V42/V34 的 88cnt 双 MCU 路线生成。V43 不改变指令流和功能 RTL，只改变板级 PLL 输出频率并重新执行 no-ILA Vivado bitstream 实现。",
        "",
        "## 扫频结果",
        "",
        "| 请求频率 | 实际频率 | bitstream | WNS | WHS | LUT | FF | DSP | 理论时间(us) | 结论 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        lines.append(
            f"| {row['requested_mhz']} | {row['freq_mhz']} | {row['bitstream_generated']} | "
            f"{row['WNS']} | {row['WHS']} | {row['LUT']} | {row['FF']} | {row['DSP']} | "
            f"{row['theoretical_time_us']} | {row['conclusion']} |"
        )

    valid = [
        row for row in rows
        if row["bitstream_generated"] == "yes" and row["WNS"] and float(row["WNS"]) >= 0.0
    ]
    lines += ["", "## 当前结论", ""]
    if valid:
        best = max(valid, key=lambda row: float(row["freq_mhz"]))
        lines.append(
            f"当前最高时序通过频点为 {best['freq_mhz']} MHz，"
            f"`cnt_test={CNT_TEST}`，理论执行时间约 {best['theoretical_time_us']} us。"
        )
        failed = [
            row for row in rows
            if row["bitstream_generated"] == "yes" and row["conclusion"].startswith("timing_failed")
        ]
        if failed:
            labels = "、".join(f"{row['freq_mhz']} MHz(WNS {row['WNS']} ns)" for row in failed)
            lines.append(f"{labels} 均已生成 bitstream，但 setup 时序不收敛，不能进入有效速度榜。")
    else:
        lines.append("本轮没有找到高于基线且时序通过的可用频点。")
    lines.append("")
    lines.append("340 MHz 和 360 MHz 若被标记为 `blocked_plle2_vco_range`，表示对应整数 PLL 配置下 VCO 超出 7 Series PLLE2 常用合法范围，不能作为有效实现成绩。")

    report_path = ROUTE_ROOT / "HIGH_FREQ_SWEEP_REPORT.md"
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report_path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vivado", default=r"D:\vivado\2025.2\Vivado\bin\vivado.bat")
    parser.add_argument("--only", default="", help="comma separated labels, for example 300,320")
    args = parser.parse_args()

    only = {item.strip() for item in args.only.split(",") if item.strip()}
    rows = []
    for point in SWEEP_POINTS:
        skip = bool(only) and point["label"] not in only
        rows.append(result_row(point, vivado=args.vivado, skip_build=skip))

    csv_path = write_csv(rows)
    report_path = write_report(rows)
    print(f"Wrote {csv_path}")
    print(f"Wrote {report_path}")


if __name__ == "__main__":
    main()
