# speed_v8_high_freq_sweep

Goal: Route A3/A4 high-frequency implementation sweep for the recommended v7
route.

Starting point:

- Copied from `speed_v7_q7_narrow_mul`, because that route preserves official
  correctness while reducing multiplier width.

Current status:

- Functional regression results are inherited from the copied v7 route.
- Vivado 2025.2 is available on the Windows host.
- Final multi-route comparison is tracked in
  `../speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`.
- This single-route sweep remains as a focused debug helper for v7 only.

Run in Vivado:

```tcl
cd mcu_fft_high_freq_sweep
source vivado/run_high_freq_sweep.tcl
```

Before using results for comparison, record `WNS`, `LUT`, `FF`, `DSP`, `BRAM`,
target frequency, and whether the bitstream excludes ILA. Official resource
and speed comparisons should use `flatten_hierarchy=none`, `max_dsp=0`, and
ILA disabled.
