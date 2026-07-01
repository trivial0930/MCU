#!/usr/bin/env python3
import argparse
import csv
import re
from pathlib import Path


PROJECT_RE = re.compile(
    r"(?P<route>speed_v\d+[a-z]?_[A-Za-z0-9_]+)_(?P<mhz>\d+)mhz_(?P<strategy>.+)$"
)


def read_text(path):
    return Path(path).read_text(encoding="utf-8", errors="ignore")


def parse_wns(text):
    patterns = [
        r"\bWNS\(ns\)\s+TNS\(ns\).*?\n\s*(-?\d+(?:\.\d+)?)",
        r"\bWNS\s*[:=]\s*(-?\d+(?:\.\d+)?)",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.S)
        if match:
            return match.group(1)
    return ""


def parse_util(text):
    result = {"lut": "", "ff": "", "dsp": "", "bram": ""}

    lut = re.search(r"\|\s*CLB LUTs\s*\|\s*(\d+)", text)
    ff = re.search(r"\|\s*CLB Registers\s*\|\s*(\d+)", text)
    dsp = re.search(r"\|\s*DSPs\s*\|\s*(\d+)", text)
    bram = re.search(r"\|\s*Block RAM Tile\s*\|\s*(\d+)", text)

    if lut:
        result["lut"] = lut.group(1)
    if ff:
        result["ff"] = ff.group(1)
    if dsp:
        result["dsp"] = dsp.group(1)
    if bram:
        result["bram"] = bram.group(1)
    return result


def parse_project(project_dir):
    name = project_dir.name
    match = PROJECT_RE.match(name)
    if match:
        route = match.group("route")
        target = match.group("mhz")
        strategy = match.group("strategy")
    else:
        route = name
        target = ""
        strategy = ""

    timing = next(project_dir.glob("*_timing_summary.rpt"), None)
    util = next(project_dir.glob("*_utilization.rpt"), None)
    row = {
        "route": route,
        "target_mhz": target,
        "strategy": strategy,
        "wns_ns": "",
        "lut": "",
        "ff": "",
        "dsp": "",
        "bram": "",
        "status": "missing_reports",
        "notes": "",
    }

    if timing:
        row["wns_ns"] = parse_wns(read_text(timing))
    if util:
        row.update(parse_util(read_text(util)))
    if timing and util:
        row["status"] = "ok" if row["wns_ns"] else "parse_check_needed"
    return row


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    root = Path(args.root)
    rows = [parse_project(path) for path in sorted(root.iterdir()) if path.is_dir()]
    fields = ["route", "target_mhz", "strategy", "wns_ns", "lut", "ff", "dsp", "bram", "status", "notes"]

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    print(f"wrote {out} with {len(rows)} rows")


if __name__ == "__main__":
    main()
