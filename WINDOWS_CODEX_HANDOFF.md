# Windows Codex + Vivado Handoff

Use this guide when opening the GitHub repository on a Windows machine with
Vivado installed.

## 1. Clone Or Update

```powershell
git clone https://github.com/trivial0930/MCU.git
cd MCU
git pull origin main
```

The route A work is already merged into `main`.

## 2. What To Feed Codex

Open the repository root `MCU` in Codex on Windows. The important entry points
are:

- `materials/README.md`: course documents and official sample data.
- `routes/README.md`: route inventory and local regression command.
- `routes/ROUTE_A_BOARD_BRINGUP_GUIDE.md`: K7EDAEVAL bring-up guide.
- `routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul`: recommended first
  hardware route.
- `routes/speed_v8_route_a_vivado_matrix`: Vivado comparison scripts for all
  route A multiplier candidates.

## 3. Local Functional Regression

If Python and Icarus Verilog are available on Windows:

```powershell
python routes/scripts/run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

If Icarus is not available, skip this step and use Vivado simulation or go
straight to implementation after confirming the committed result files.

## 4. First Vivado Board Project

Start with the narrow Q7 multiplier route:

```powershell
cd routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
vivado
```

In Vivado Tcl Console:

```tcl
set PART_NAME xc7k325tffg900-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
source ../../vivado/create_board_project.tcl
```

Then run:

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary
report_utilization
```

Use `ENABLE_ILA 1` for first bring-up and `ENABLE_ILA 0` for final resource
comparison.

## 5. Route A Timing Matrix

To compare all route A multiplier implementations:

```powershell
cd routes/speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado/run_route_a_matrix.tcl
python scripts/parse_vivado_reports.py --root build/vivado_matrix --out results/route_a_matrix.csv
```

Send the generated `results/route_a_matrix.csv` and any failing
`*_timing_summary.rpt` files back into Codex for analysis.

## 6. Important Clock Note

The current board top uses the board `CLK_50M` directly:

```verilog
assign clk = CLK_50M;
```

The 95/100/110/120/130 MHz scripts are timing-target sweeps. True high-frequency
operation on hardware requires adding a PLL/MMCM or another valid high-frequency
clock source, then updating `board_top.v` and constraints.
