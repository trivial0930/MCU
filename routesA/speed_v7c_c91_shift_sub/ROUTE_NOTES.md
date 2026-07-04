# speed_v7c_c91_shift_sub

Goal: Route A2 alternate constant multiplier experiment.

Difference from `speed_v6_official_sample`:

- `rtl/alu.v` implements `a * 91 >>> 7` as:
  `128a - 32a - 4a - a`, then arithmetic right shift by 7.

Why keep this separate from `speed_v7b_c91_shift_add`:

- Both are constant-91 implementations, but they produce different adder and
  subtractor structures after synthesis. Vivado should decide which one wins
  on `WNS`, `LUT`, `FF`, and `DSP`.

Important boundary:

- Like `speed_v7b_c91_shift_add`, this route specializes `MUL` for the FFT
  program's constant `91`. It is not a general-purpose multiply route.

Local verification:

- Official `FFT_input.coe` / `FFT_output.coe`: PASS.
- Random seeds `2026-2045`: PASS.
- Generated instruction count: `162`.
- Observed simulation `cnt_test`: `157`.
