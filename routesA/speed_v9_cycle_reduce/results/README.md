# speed_v9_cycle_reduce results

This folder records the first Route B cycle-reduction prototype.

Summary:

- Functional regression: official sample PASS, random seeds `2026-2045` PASS.
- Instruction count: `156`.
- `cnt_test`: `151`.
- Best clean Vivado point so far: `120 MHz`, WNS `0.091 ns`.
- `130 MHz` is implemented but fails timing with WNS `-0.140 ns`.

The full Vivado projects were run from a short mapped path and are intentionally
not committed:

```text
D:/vivado_work/mcu_v9_120
D:/vivado_work/mcu_v9_130_fix
```

Use `../run_vivado_130.tcl` for the 130 MHz retry entry point.
