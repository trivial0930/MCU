# MCU FFT route log

This directory keeps each route in a separate folder so failed experiments can
be abandoned without losing earlier working versions.

## Route summary

| Route | Purpose | Current local check |
| --- | --- | --- |
| `speed_v5_main_freeze/` | Frozen copy of the GitHub `main` baseline as received. Uses the original interleaved 16-word test format and Q15 multiply. | Baseline self-check PASS before route work; observed `cnt_test=224`. |
| `speed_v6_official_sample/` | Official 2026 FFT sample compatibility: 256-word test ROM address space, official addresses 128-143, Q5-to-Q12 read conversion, Q7 multiply, corrected DIF flow, official real-then-imag output layout. | Official sample PASS, 20 random fixed-point regressions PASS, `162` instructions, `cnt_test=157`. |
| `speed_v7_q7_narrow_mul/` | Route A1. Same behavior as v6, but ALU Q7 multiply is narrowed to data x 8-bit coefficient. | Official sample PASS, 20 random regressions PASS, `cnt_test=157`. |
| `speed_v7b_c91_shift_add/` | Route A2 alternate. Same behavior as v6 for this FFT program, but `MUL` is specialized as constant `91` shift-add. | Official sample PASS, 20 random regressions PASS, `cnt_test=157`. |
| `speed_v7c_c91_shift_sub/` | Route A2 alternate. Same behavior as v6 for this FFT program, but `MUL` is specialized as `91 = 128 - 32 - 4 - 1`. | Official sample PASS, 20 random regressions PASS, `cnt_test=157`. |
| `speed_v8_high_freq_sweep/` | Route A3/A4. Vivado timing/resource sweep scaffold based on the v7 narrow-multiply RTL. | Not run locally because Vivado is not installed on this machine. |
| `speed_v8_route_a_vivado_matrix/` | Route A3/A4 comparison matrix for v6, v7, v7b, and v7c across target clocks and Vivado strategies. | Scripted only; not run locally because Vivado is not installed on this machine. |

## Re-run local regression

From any verified route project directory:

```sh
python3 scripts/run_official_regression.py --random-cases 20 --seed 2026
```

The command regenerates the official assembly, converts `mem/FFT_input.coe` to
`mem/FFT_input.mem`, rebuilds the instruction ROM, runs Icarus Verilog, and
checks the official sample plus random cases against the software fixed-point
model.

To run all route A RTL candidates at once:

```sh
python3 routes/scripts/run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

## Vivado note

Real speed ranking still needs post-implementation timing/resource data:
`WNS`, `LUT`, `FF`, `DSP`, `BRAM`, and the final working clock. The local
machine used for this pass does not provide `vivado`, so the HDL is simulation
checked but not implementation checked here.

## Board bring-up

See `ROUTE_A_BOARD_BRINGUP_GUIDE.md` for K7EDAEVAL bring-up, ILA, bitstream,
and route A high-frequency comparison steps.
