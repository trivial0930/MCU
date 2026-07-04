#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path


def to_float(value, default=None):
    try:
        return float(value)
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


def prepared_rows(rows):
    result = []
    for row in rows:
        wns = to_float(row.get("wns_ns"))
        mhz = to_float(row.get("target_mhz"))
        lut = to_float(row.get("lut"))
        ff = to_float(row.get("ff"), 0)
        dsp = to_float(row.get("dsp"), 999)
        if wns is None or mhz is None or lut is None:
            continue
        row = dict(row)
        row["_wns"] = wns
        row["_mhz"] = mhz
        row["_lut"] = lut
        row["_ff"] = ff or 0
        row["_dsp"] = dsp
        result.append(row)
    return result


def clean(row):
    return {k: v for k, v in row.items() if not k.startswith("_")}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in-csv", default="results/route_a_matrix.csv")
    parser.add_argument("--speed-out", default="results/speed_leaderboard.csv")
    parser.add_argument("--eff-out", default="results/efficiency_leaderboard.csv")
    args = parser.parse_args()

    rows = prepared_rows(read_rows(args.in_csv))

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

    fields = ["route", "target_mhz", "strategy", "wns_ns", "lut", "ff", "dsp", "bram", "status", "notes"]
    eff_fields = fields + ["mhz_per_lut", "mhz_per_lut_ff"]
    write_rows(args.speed_out, speed_rows, fields)
    write_rows(args.eff_out, eff_rows, eff_fields)
    print(f"wrote {args.speed_out} with {len(speed_rows)} rows")
    print(f"wrote {args.eff_out} with {len(eff_rows)} rows")


if __name__ == "__main__":
    main()
