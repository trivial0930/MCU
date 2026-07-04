# Windows Codex + Vivado 继续调试清单

这份文档用于在 Windows 机器上接着完成 MCU FFT 路线 A 的仿真、Vivado 实现、上板和结果回填。建议把仓库根目录直接作为 Codex 工作区打开。

## 1. 拉取仓库

```powershell
git clone https://github.com/trivial0930/MCU.git
cd MCU
git pull origin main
```

如果已经在本地有仓库，先确认没有未保存改动：

```powershell
git status --short --branch
```

## 2. 工具链检查

```powershell
py --version
where vivado
where iverilog
where vvp
```

- 只做 Vivado 实现：必须能找到 `vivado`。
- 做本地 Verilog 回归：必须能找到 `iverilog` 和 `vvp`。
- 当前脚本已加入预检，缺工具时会提前退出并说明原因。

## 3. 功能回归

从仓库根目录运行四条路线的统一回归：

```powershell
py routes\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

缺少 Icarus Verilog 时可以跳过此步，但上板前至少应确认仓库中已有的 `results/regression_summary.txt` 与 `results/route_a_regression.log` 是通过版本。

## 4. 推荐上板路线

优先从 `speed_v7_q7_narrow_mul` 开始，因为它保持 Q7 乘法语义，同时减少乘法器宽度，风险低于常数 91 专用路线。

```powershell
cd routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
vivado
```

Vivado Tcl Console：

```tcl
set PART_NAME xc7k160tffg676-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0
source ../../vivado/create_board_project.tcl
```

然后执行：

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary
report_utilization
```

首次上板建议 `ENABLE_ILA 1`，最终资源和频率比较建议 `ENABLE_ILA 0`。

## 5. 推荐重新生成 bitstream

推荐先映射短路径，避免中文路径、OneDrive 和长路径影响 Vivado：

```powershell
subst M: C:\Users\戎择辰\OneDrive\文档\数电实验\MCU
cd M:\routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
```

带 ILA 调试版建议使用 OneDrive 外的输出目录：

```powershell
@'
set ENABLE_ILA 1
set TARGET_PERIOD_NS 20.000
set PART_NAME xc7k160tffg676-2
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0
set JOBS 4
set OUT_DIR D:/vivado_work/mcu_q7_ila
source ../../vivado/run_board_bitstream.tcl
'@ | D:\vivado\2025.2\Vivado\bin\vivado.bat -mode tcl -nolog -nojournal
```

## 6. 路线 A 高频矩阵

如需继续比较 v6/v7/v7b/v7c 的高频余量，运行：

```powershell
cd routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```

脚本会为每个组合生成：

- `*_timing_summary.rpt`
- `*_utilization.rpt`
- `*_design_analysis_timing.rpt`
- `*_routed.dcp`
- `run_status.txt`

把 `results/route_a_matrix.csv` 和失败组合的 timing report 交给 Codex，即可继续分析瓶颈。

## 7. 重要时钟说明

当前 `rtl/board_top.v` 直接使用板载 50 MHz：

```verilog
assign clk = CLK_50M;
```

95/100/110/120/130 MHz 脚本是时序目标 sweep，用于判断 RTL 在该目标下是否能收敛。若需要板上真实运行到 95 MHz 以上，需要额外加入 PLL/MMCM 或外部高频时钟，并同步更新 `board_top.v` 和约束。

## 8. 推荐交付物

完成 Vivado 调试后，建议回填：

- `routes/speed_v8_route_a_vivado_matrix/results/route_a_matrix.csv`
- 最终路线的 timing/utilization report
- 选择最终路线的理由：频率、WNS、资源、DSP 是否为 0、是否带 ILA
- 若修改 RTL，需要重新跑功能回归并更新对应路线说明

当前已完成的首板交付物和上板步骤见 `docs/上板与交接指南.md`。
