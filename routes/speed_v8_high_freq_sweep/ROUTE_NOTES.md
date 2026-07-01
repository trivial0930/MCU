# speed_v8_high_freq_sweep

Goal: Route A3/A4 high-frequency implementation sweep.

Starting point:

- Copied from `speed_v7_q7_narrow_mul`, because that route preserves official
  correctness while reducing multiplier width.

Local state:

- Functional regression results are inherited from the copied v7 route.
- Vivado timing/resource sweep has not been run locally because `vivado` is not
  installed on this machine.

Run in Vivado:

```tcl
cd mcu_fft_high_freq_sweep
source vivado/run_high_freq_sweep.tcl
```

Before using results for comparison, record `WNS`, `LUT`, `FF`, `DSP`, `BRAM`,
target frequency, and whether the bitstream excludes ILA.
