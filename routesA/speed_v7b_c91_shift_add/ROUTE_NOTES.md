# speed_v7b_c91_shift_add

Goal: Route A2 constant multiplier experiment for the only non-trivial FFT
twiddle coefficient used by this 8-point program.

Difference from `speed_v6_official_sample`:

- `rtl/alu.v` implements `a * 91 >>> 7` as:
  `64a + 16a + 8a + 2a + a`, then arithmetic right shift by 7.

Important boundary:

- This route specializes `MUL` for the FFT program's constant `91`. Do not use
  it as a general-purpose MCU multiply route unless the ISA is extended to
  distinguish generic multiply from constant-twiddle multiply.

Local verification:

- Official `FFT_input.coe` / `FFT_output.coe`: PASS.
- Random seeds `2026-2045`: PASS.
- Generated instruction count: `162`.
- Observed simulation `cnt_test`: `157`.
