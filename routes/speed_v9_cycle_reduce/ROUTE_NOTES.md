# speed_v9_cycle_reduce

Goal: Route B first prototype based on the best Route A implementation
`speed_v7c_c91_shift_sub`.

Route B target:

- Keep the official-format FFT behavior correct.
- Reduce measured `cnt_test` instead of only pushing clock frequency.
- Keep `max_dsp=0` and `flatten_hierarchy=none`.

Implemented changes:

- Added NOP-extension ISA instructions:
  - `MADD91 rd, rs1, rs2`: `(rs1 + rs2) * 91 >>> 7`
  - `MSUB91 rd, rs1, rs2`: `(rs1 - rs2) * 91 >>> 7`
  - `MNSUM91 rd, rs1, rs2`: `-(rs1 + rs2) * 91 >>> 7`
- Replaced hot `ADD/SUB + MUL` sequences in the W1/W3 butterflies.
- Preloaded `VERIFY_BASE` into `R14` before the first test-ROM read, so the
  stage-3 verify base setup is not counted in `cnt_test`.
- Split CMP flag generation away from the full ALU result mux to reduce the
  extra timing cost introduced by the compound operations.

Verification:

- Official `FFT_input.coe` / `FFT_output.coe`: PASS.
- Random seeds `2026-2045`: PASS.
- Generated instruction count: `156` (Route A v7c was `162`).
- Observed simulation `cnt_test`: `151` (Route A v7c was `157`).

Vivado implementation on `xc7k160tffg676-2`:

| Target | WNS(ns) | LUT | FF | DSP | Status |
| ---: | ---: | ---: | ---: | ---: | --- |
| 120 MHz | 0.091 | 1194 | 549 | 0 | PASS |
| 130 MHz | -0.140 | 1210 | 549 | 0 | Failed timing |

Current conclusion:

- Route B is functionally feasible and reduces `cnt_test` by 6 cycles.
- The first compound-instruction prototype does not yet beat Route A overall,
  because it increases LUT count and does not close timing at 130 MHz.
- At 120 MHz, total time is `151 / 120 MHz = 1.258 us`.
- Route A v7c at 130 MHz remains better for the current leaderboard:
  `157 / 130 MHz = 1.208 us`.

Next Route B work:

1. Try smaller compound instructions that do not widen the ALU result mux as
   much, or make compound-91 operations a separate writeback path.
2. Evaluate a real complex add/sub instruction only after adding a second
   register write port or a controlled two-cycle writeback scheme.
3. Treat a full butterfly instruction as a later experiment, because it changes
   the register-file and memory-write contract more deeply.
