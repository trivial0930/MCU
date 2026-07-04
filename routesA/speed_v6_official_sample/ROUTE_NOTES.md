# speed_v6_official_sample

Goal: establish the official sample compatible version before doing multiplier
or frequency experiments.

Key changes from the received GitHub `main` baseline:

- `test_rom_addr` widened to 8 bits and `test_ROM` depth widened to 256 words.
- Official input addresses `128-135` and `136-143` are read directly by the
  first DIF stage.
- `ext_test_rom_if` converts official Q5 samples to internal Q12 by left
  shifting those reads by 7 bits.
- `MUL` now performs Q7 fixed-point multiply.
- The FFT flow is corrected to DIF: `sum = a + b`, `diff = a - b`,
  `lower = diff * W`.
- The final DIF stage writes directly to official output layout:
  `verify[0:7] = real`, `verify[8:15] = imag`.

Local verification:

- Official `FFT_input.coe` / `FFT_output.coe`: PASS.
- Random seeds `2026-2045`: PASS.
- Generated instruction count: `162`.
- Observed simulation `cnt_test`: `157`.

Re-run:

```sh
cd mcu_fft_official_sample
python3 scripts/run_official_regression.py --random-cases 20 --seed 2026
```
