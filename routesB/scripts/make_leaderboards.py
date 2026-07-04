#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path


def to_float(value, default=None):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def to_int(value, default=None):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def read_rows(path):
    with Path(path).open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def write_rows(path, rows, fields):
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def read_cycle_summary(path):
    summary = {}
    p = Path(path)
    if not p.exists():
        return summary
    for row in read_rows(p):
        summary[row["route"]] = row
    return summary


def prepared_rows(rows, cycle_summary):
    result = []
    for row in rows:
        route = row.get("route", "")
        cycles = to_int(cycle_summary.get(route, {}).get("cnt_test"))
        instr = to_int(cycle_summary.get(route, {}).get("instruction_count"))
        wns = to_float(row.get("wns_ns"))
        mhz = to_float(row.get("target_mhz"))
        lut = to_float(row.get("lut"))
        ff = to_float(row.get("ff"), 0)
        dsp = to_float(row.get("dsp"), 999)
        if wns is None or mhz is None or lut is None:
            continue
        row = dict(row)
        row["instruction_count"] = "" if instr is None else str(instr)
        row["cnt_test"] = "" if cycles is None else str(cycles)
        row["_wns"] = wns
        row["_mhz"] = mhz
        row["_lut"] = lut
        row["_ff"] = ff or 0
        row["_dsp"] = dsp
        row["_cnt"] = cycles
        row["_time_us"] = cycles / mhz if cycles is not None and mhz else None
        if row["_time_us"] is not None:
            row["total_time_us"] = f"{row['_time_us']:.3f}"
        else:
            row["total_time_us"] = ""
        result.append(row)
    return result


def clean(row):
    return {k: v for k, v in row.items() if not k.startswith("_")}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in-csv", default="results/route_b_matrix.csv")
    parser.add_argument("--summary-csv", "--cycle-csv", dest="summary_csv", default="results/route_b_summary.csv")
    parser.add_argument("--out-dir", default=None)
    parser.add_argument("--speed-out", default=None)
    parser.add_argument("--time-out", default=None)
    parser.add_argument("--eff-out", default=None)
    args = parser.parse_args()

    out_dir = Path(args.out_dir) if args.out_dir else Path("results")
    speed_out = args.speed_out or out_dir / "route_b_speed_leaderboard.csv"
    time_out = args.time_out or out_dir / "route_b_time_leaderboard.csv"
    eff_out = args.eff_out or out_dir / "route_b_efficiency_leaderboard.csv"

    rows = prepared_rows(read_rows(args.in_csv), read_cycle_summary(args.summary_csv))
    valid = [row for row in rows if row["_wns"] >= 0 and row["_dsp"] == 0]

    routes = sorted({row["route"] for row in rows})
    best_by_route = {}
    for route in routes:
        route_valid = [row for row in valid if row["route"] == route]
        if route_valid:
            best = sorted(route_valid, key=lambda r: (r["_mhz"], r["_wns"], -r["_lut"], -r["_ff"]), reverse=True)[0]
            best_by_route[route] = best
        else:
            route_rows = [row for row in rows if row["route"] == route]
            if route_rows:
                best = sorted(route_rows, key=lambda r: (r["_wns"], r["_mhz"]), reverse=True)[0]
                best = dict(best)
                best["status"] = "no_passing_result"
                best["notes"] = "No result met WNS>=0 and DSP=0 in the tested targets"
                best_by_route[route] = best

    speed_rows = [clean(row) for row in sorted(
        best_by_route.values(),
        key=lambda r: (1 if r.get("status") != "no_passing_result" else 0, r["_mhz"], r["_wns"], -r["_lut"], -r["_ff"]),
        reverse=True,
    )]

    time_rows = [clean(row) for row in sorted(
        [row for row in valid if row["_time_us"] is not None],
        key=lambda r: (r["_time_us"], -r["_mhz"], r["_lut"], r["_ff"]),
    )]

    eff_rows = []
    for row in valid:
        out = clean(row)
        mhz_per_lut = row["_mhz"] / row["_lut"] if row["_lut"] else 0
        mhz_per_lut_ff = row["_mhz"] / (row["_lut"] + row["_ff"]) if row["_lut"] + row["_ff"] else 0
        out["mhz_per_lut"] = f"{mhz_per_lut:.6f}"
        out["mhz_per_lut_ff"] = f"{mhz_per_lut_ff:.6f}"
        eff_rows.append(out)
    eff_rows.sort(
        key=lambda r: (to_float(r["mhz_per_lut"], 0), to_float(r["target_mhz"], 0), to_float(r["wns_ns"], 0)),
        reverse=True,
    )

    fields = [
        "route", "target_mhz", "strategy", "wns_ns", "lut", "ff", "dsp", "bram",
        "instruction_count", "cnt_test", "total_time_us", "status", "notes",
    ]
    eff_fields = fields + ["mhz_per_lut", "mhz_per_lut_ff"]
    write_rows(speed_out, speed_rows, fields)
    write_rows(time_out, time_rows, fields)
    write_rows(eff_out, eff_rows, eff_fields)
    print(f"wrote {speed_out} with {len(speed_rows)} rows")
    print(f"wrote {time_out} with {len(time_rows)} rows")
    print(f"wrote {eff_out} with {len(eff_rows)} rows")


if __name__ == "__main__":
    main()
