# speed_v7_q7_narrow_mul

Goal: Route A1 multiplier narrowing while preserving v6 behavior.

Difference from `speed_v6_official_sample`:

- `rtl/alu.v` implements Q7 multiply as signed 25-bit data by signed 8-bit
  coefficient, then arithmetic right shift by 7.

Why this route is separate:

- It should be compared against v6 in Vivado for `WNS`, `LUT`, `FF`, `DSP`, and
  `BRAM`.
- It keeps the same assembly and test flow, so timing/resource differences are
  attributable to the multiplier implementation.

Local verification:

- Official `FFT_input.coe` / `FFT_output.coe`: PASS.
- Random seeds `2026-2045`: PASS.
- Generated instruction count: `162`.
- Observed simulation `cnt_test`: `157`.
