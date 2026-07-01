# speed_v5_main_freeze

Purpose: preserve the received GitHub `main` baseline before any official-format
or multiplier route work.

Observed local baseline behavior before route work:

- Original interleaved 16-word input format.
- Original Q15 `MUL` semantics.
- Baseline FFT self-check: PASS.
- Observed simulation `cnt_test`: `224`.

Note:

- The public GitHub repository cloned in this workspace only exposed `main`.
  A separate `speed_v5_cnt160_95MHz` branch was not present locally, so this
  route freezes the available baseline rather than an unavailable branch.
