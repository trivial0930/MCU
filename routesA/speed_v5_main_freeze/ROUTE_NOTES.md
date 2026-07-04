# speed_v5_main_freeze

Purpose: preserve the received GitHub `main` baseline before any official-format
or multiplier route work.

The former top-level `Baseline/` copy has been removed to avoid duplicate code.
This route is now the single archived baseline entry.

Observed local baseline behavior before route work:

- Original interleaved 16-word input format.
- Original Q15 `MUL` semantics.
- Baseline FFT self-check: PASS.
- Observed simulation `cnt_test`: `224`.
- Board constraint cleanup: KEY1 uses `LVCMOS18`, matching the HP bank voltage
  requirement used by later routes.

Note:

- The public GitHub repository cloned in this workspace only exposed `main`.
  A separate `speed_v5_cnt160_95MHz` branch was not present locally, so this
  route freezes the available baseline rather than an unavailable branch.
