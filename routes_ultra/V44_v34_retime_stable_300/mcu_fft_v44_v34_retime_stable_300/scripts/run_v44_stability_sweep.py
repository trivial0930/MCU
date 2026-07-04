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
ROUTES_ULTRA = ROUTE_ROOT.parents[1]
RESULTS_DIR = ROUTE_ROOT / "results"
BASELINE_ROUTE = (
    ROUTES_ULTRA
    / "V42_v34_board_verified_300"
    / "mcu_fft_v42_v34_board_verified_300"
)
CNT_TEST = 88

VARIANTS = [
    {
        "name": "postroute_physopt",
        "impl_strategy": "Performance_ExplorePostRoutePhysOpt",
        "synth_settings": [],
        "impl_settings": [
            ("STEPS.OPT_DESIGN.ARGS.DIRECTIVE", "Explore"),
            ("STEPS.PLACE_DESIGN.ARGS.DIRECTIVE", "ExtraNetDelay_high"),
            ("STEPS.PHYS_OPT_DESIGN.IS_ENABLED", "true"),
            ("STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE", "AggressiveExplore"),
            ("STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE", "Explore"),
        ],
    },
    {
        "name": "netdelay_high",
        "impl_strategy": "Performance_NetDelay_high",
        "synth_settings": [],
        "impl_settings": [
            ("STEPS.OPT_DESIGN.ARGS.DIRECTIVE", "ExploreWithRemap"),
            ("STEPS.PLACE_DESIGN.ARGS.DIRECTIVE", "ExtraNetDelay_high"),
            ("STEPS.PHYS_OPT_DESIGN.IS_ENABLED", "true"),
            ("STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE", "AggressiveExplore"),
            ("STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE", "NoTimingRelaxation"),
        ],
    },
    {
        "name": "retiming_try",
        "impl_strategy": "Performance_ExplorePostRoutePhysOpt",
        "synth_settings": [
            ("STEPS.SYNTH_DESIGN.ARGS.RETIMING", "true"),
            ("STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS", "false"),
        ],
        "impl_settings": [
            ("STEPS.OPT_DESIGN.ARGS.DIRECTIVE", "Explore"),
            ("STEPS.PLACE_DESIGN.ARGS.DIRECTIVE", "ExtraNetDelay_high"),
            ("STEPS.PHYS_OPT_DESIGN.IS_ENABLED", "true"),
            ("STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE", "AggressiveExplore"),
            ("STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE", "Explore"),
        ],
    },
]


def read_text(path):
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except FileNotFoundError:
        return ""


def parse_status(path):
    status = ""
    notes = ""
    for line in read_text(path).splitlines():
        if line.startswith("status="):
            status = line.split("=", 1)[1].strip()
        elif line.startswith("notes="):
            notes = line.split("=", 1)[1].strip()
    return status, notes


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


def extract_worst_path(src, dst):
    text = read_text(src)
    start = text.find("Max Delay Paths")
    if start < 0:
        dst.write_text("未找到 Max Delay Paths。\n", encoding="utf-8")
        return
    end = text.find("Min Delay Paths", start)
    if end < 0:
        end = start + 9000
    dst.write_text(text[start:end].strip() + "\n", encoding="utf-8")


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


def write_variant_tcl(variant):
    build_dir = ROUTE_ROOT / "build" / "v44_stability"
    build_dir.mkdir(parents=True, exist_ok=True)
    tcl_path = build_dir / f"{variant['name']}.tcl"
    out_dir = Path("D:/vivado_work/routes_ultra") / f"mcu_fft_v44_{variant['name']}"
    result_dir = RESULTS_DIR / f"vivado_{variant['name']}"

    lines = [
        "set ENABLE_ILA 0",
        "set TARGET_PERIOD_NS 20.000",
        "set SYNTH_FLATTEN_HIERARCHY none",
        "set SYNTH_MAX_DSP 0",
        "set PART_NAME xc7k160tffg676-2",
        "set JOBS 4",
        f"set OUT_DIR {{{out_dir.as_posix()}}}",
        f"set V44_RESULTS_DIR [file normalize [file join [pwd] results vivado_{variant['name']}]]",
        "proc write_status {path status notes} {",
        "    set fd [open $path w]",
        "    puts $fd \"status=$status\"",
        "    puts $fd \"notes=$notes\"",
        "    close $fd",
        "}",
        "proc try_prop {notes_var obj prop value} {",
        "    upvar $notes_var notes",
        "    if {[catch {set_property $prop $value $obj} err]} {",
        "        lappend notes \"${prop}_failed=$err\"",
        "    } else {",
        "        lappend notes \"${prop}=$value\"",
        "    }",
        "}",
        "set root_dir [file normalize [pwd]]",
        "file mkdir $V44_RESULTS_DIR",
        "set status_file [file join $V44_RESULTS_DIR board_bitstream_status.txt]",
        "set board_script [file normalize [file join $root_dir .. .. vivado create_board_project.tcl]]",
        "if {![file exists $board_script]} {",
        "    write_status $status_file failed \"missing_create_board_project=$board_script\"",
        "    error \"missing create_board_project.tcl\"",
        "}",
        "if {[catch {source $board_script} err]} {",
        "    write_status $status_file failed \"create_project_error=$err\"",
        "    error $err",
        "}",
        "set notes {}",
        "set synth_run [get_runs synth_1]",
        "set impl_run [get_runs impl_1]",
        f"try_prop notes $impl_run strategy {variant['impl_strategy']}",
    ]
    for prop, value in variant["synth_settings"]:
        lines.append(f"try_prop notes $synth_run {prop} {value}")
    for prop, value in variant["impl_settings"]:
        lines.append(f"try_prop notes $impl_run {prop} {value}")

    lines += [
        "set run_error \"\"",
        "if {[catch {",
        "    launch_runs synth_1 -jobs $JOBS",
        "    wait_on_run synth_1",
        "    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS",
        "    wait_on_run impl_1",
        "} run_error]} {",
        "    write_status $status_file failed \"run_error=$run_error notes=$notes\"",
        "    error $run_error",
        "}",
        "set synth_status [get_property STATUS [get_runs synth_1]]",
        "set impl_status [get_property STATUS [get_runs impl_1]]",
        "if {[catch {open_run impl_1} err]} {",
        "    write_status $status_file failed \"open_impl_error=$err synth_status=$synth_status impl_status=$impl_status notes=$notes\"",
        "    error $err",
        "}",
        "report_timing_summary -file [file join $V44_RESULTS_DIR board_timing_summary.rpt]",
        "report_utilization -file [file join $V44_RESULTS_DIR board_utilization.rpt]",
        "report_utilization -hierarchical -file [file join $V44_RESULTS_DIR board_utilization_hierarchical.rpt]",
        "report_drc -file [file join $V44_RESULTS_DIR board_drc.rpt]",
        "report_methodology -file [file join $V44_RESULTS_DIR board_methodology.rpt]",
        "set bit_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.bit]]",
        "set ltx_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.ltx]]",
        "write_status $status_file ok \"variant="
        + variant["name"]
        + " synth_status=$synth_status impl_status=$impl_status notes=$notes bit_files=$bit_files ltx_files=$ltx_files\"",
        "puts \"V44 variant complete.\"",
        "puts \"Reports: $V44_RESULTS_DIR\"",
        "puts \"Bitstream files: $bit_files\"",
    ]
    tcl_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return tcl_path, result_dir


def collect_row(variant):
    result_dir = RESULTS_DIR / f"vivado_{variant['name']}"
    status, notes = parse_status(result_dir / "board_bitstream_status.txt")
    timing = parse_timing(result_dir / "board_timing_summary.rpt")
    util = parse_util(result_dir / "board_utilization.rpt")
    row = {
        "variant": variant["name"],
        "status": status,
        "WNS": timing["WNS"],
        "TNS": timing["TNS"],
        "WHS": timing["WHS"],
        "THS": timing["THS"],
        "LUT": util["LUT"],
        "FF": util["FF"],
        "DSP": util["DSP"],
        "BRAM": util["BRAM"],
        "cnt_test": CNT_TEST,
        "conclusion": "missing_result",
        "notes": notes[:160],
    }
    if status == "ok" and row["WNS"]:
        if float(row["WNS"]) >= 0.0 and row["DSP"] == "0":
            row["conclusion"] = "timing_clean_dsp0"
        elif row["DSP"] != "0":
            row["conclusion"] = "invalid_dsp_used"
        else:
            row["conclusion"] = "timing_failed"
    return row


def run_variant(variant, vivado):
    tcl_path, result_dir = write_variant_tcl(variant)
    safe_rmtree(result_dir)
    proc = subprocess.run(
        [vivado, "-mode", "batch", "-source", str(tcl_path)],
        cwd=ROUTE_ROOT,
        text=True,
    )
    row = collect_row(variant)
    if proc.returncode != 0 and row["status"] != "ok":
        row["conclusion"] = "vivado_failed"
    return row


def write_sweep_csv(rows):
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    path = RESULTS_DIR / "v44_timing_sweep.csv"
    fieldnames = [
        "variant", "status", "WNS", "TNS", "WHS", "THS",
        "LUT", "FF", "DSP", "BRAM", "cnt_test", "conclusion", "notes",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return path


def best_row(rows):
    candidates = [r for r in rows if r["WNS"] and r["DSP"] == "0"]
    if not candidates:
        return None
    return max(candidates, key=lambda r: float(r["WNS"]))


def write_compare_and_report(rows):
    baseline_dir = BASELINE_ROUTE / "results" / "vivado_board"
    baseline_timing = parse_timing(baseline_dir / "board_timing_summary.rpt")
    baseline_util = parse_util(baseline_dir / "board_utilization.rpt")
    best = best_row(rows)

    extract_worst_path(
        baseline_dir / "board_timing_summary.rpt",
        RESULTS_DIR / "worst_path_before.txt",
    )
    if best:
        after_dir = RESULTS_DIR / f"vivado_{best['variant']}"
        extract_worst_path(
            after_dir / "board_timing_summary.rpt",
            RESULTS_DIR / "worst_path_after.txt",
        )
        best_board = RESULTS_DIR / "vivado_board"
        safe_rmtree(best_board)
        shutil.copytree(after_dir, best_board)

    compare_path = RESULTS_DIR / "timing_compare.csv"
    fieldnames = ["route", "variant", "WNS", "TNS", "WHS", "THS", "LUT", "FF", "DSP", "BRAM", "cnt_test"]
    with compare_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerow({
            "route": "V42_baseline",
            "variant": "baseline",
            "WNS": baseline_timing["WNS"],
            "TNS": baseline_timing["TNS"],
            "WHS": baseline_timing["WHS"],
            "THS": baseline_timing["THS"],
            "LUT": baseline_util["LUT"],
            "FF": baseline_util["FF"],
            "DSP": baseline_util["DSP"],
            "BRAM": baseline_util["BRAM"],
            "cnt_test": CNT_TEST,
        })
        if best:
            writer.writerow({
                "route": "V44_best_after",
                "variant": best["variant"],
                "WNS": best["WNS"],
                "TNS": best["TNS"],
                "WHS": best["WHS"],
                "THS": best["THS"],
                "LUT": best["LUT"],
                "FF": best["FF"],
                "DSP": best["DSP"],
                "BRAM": best["BRAM"],
                "cnt_test": CNT_TEST,
            })

    lines = [
        "# V44 稳定化实现报告",
        "",
        "V44 继承 V42/V34 的 88cnt 双 MCU 路线，不改变 RTL 功能和指令流。本轮只比较 Vivado no-ILA 300 MHz 实现策略。",
        "",
        "## 实现策略结果",
        "",
        "| 变体 | WNS | TNS | WHS | LUT | FF | DSP | 结论 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        lines.append(
            f"| {row['variant']} | {row['WNS']} | {row['TNS']} | {row['WHS']} | "
            f"{row['LUT']} | {row['FF']} | {row['DSP']} | {row['conclusion']} |"
        )
    lines += ["", "## 与 V42 对比", ""]
    lines.append(
        f"V42 baseline: WNS {baseline_timing['WNS']} ns, WHS {baseline_timing['WHS']} ns, "
        f"LUT/FF {baseline_util['LUT']}/{baseline_util['FF']}, DSP {baseline_util['DSP']}。"
    )
    if best:
        delta = float(best["WNS"]) - float(baseline_timing["WNS"])
        lines.append(
            f"V44 最优变体为 `{best['variant']}`：WNS {best['WNS']} ns，"
            f"相对 V42 变化 {delta:+.3f} ns，DSP {best['DSP']}。"
        )
        if float(best["WNS"]) >= 0.100:
            lines.append("结论：V44 达到 +0.100 ns 以上余量目标，可以作为更稳的 300 MHz 实现候选。")
        elif float(best["WNS"]) >= 0.0:
            lines.append("结论：V44 仍满足 300 MHz 时序，但未达到 +0.100 ns 余量目标，暂不替代 V42。")
        else:
            lines.append("结论：V44 未获得时序通过结果，不能替代 V42。")
    else:
        lines.append("未获得可比较的 V44 实现结果。")
    lines.append("")
    lines.append("详细最差路径见 `results/worst_path_before.txt` 和 `results/worst_path_after.txt`。")

    report_path = ROUTE_ROOT / "V44_STABILITY_REPORT.md"
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return compare_path, report_path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vivado", default=r"D:\vivado\2025.2\Vivado\bin\vivado.bat")
    parser.add_argument("--only", default="", help="comma separated variant names; unknown value only refreshes existing results")
    args = parser.parse_args()

    only = {item.strip() for item in args.only.split(",") if item.strip()}
    rows = []
    for variant in VARIANTS:
        if only and variant["name"] not in only:
            rows.append(collect_row(variant))
        else:
            rows.append(run_variant(variant, args.vivado))

    sweep_path = write_sweep_csv(rows)
    compare_path, report_path = write_compare_and_report(rows)
    print(f"Wrote {sweep_path}")
    print(f"Wrote {compare_path}")
    print(f"Wrote {report_path}")


if __name__ == "__main__":
    main()
