# speed_v8_route_a_vivado_matrix

Goal: Route A3/A4 implementation comparison.

This folder keeps the Vivado comparison machinery separate from the verified
RTL candidates. It compares:

- `speed_v6_official_sample`: generic Q7 multiply.
- `speed_v7_q7_narrow_mul`: narrowed data by 8-bit coefficient multiply.
- `speed_v7b_c91_shift_add`: constant 91 as `64 + 16 + 8 + 2 + 1`.
- `speed_v7c_c91_shift_sub`: constant 91 as `128 - 32 - 4 - 1`.

Run in a machine with Vivado:

```tcl
cd routes/speed_v8_route_a_vivado_matrix
source vivado/run_route_a_matrix.tcl
```

Then parse reports:

```sh
python3 scripts/parse_vivado_reports.py --root build/vivado_matrix --out results/route_a_matrix.csv
```

Local state:

- Not run here because `vivado` is not installed.
- Do not choose a final high-frequency route until post-route `WNS`, `LUT`,
  `FF`, `DSP`, and `BRAM` are recorded for all candidates.
