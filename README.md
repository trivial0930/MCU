# MCU FFT 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU 实验中的 8 点定点复数 FFT 任务。设计目标是在不直接例化 FFT IP、DSP IP 或专用 FFT 加速器的前提下，用自研轻量 MCU 执行普通指令完成 FFT 计算，并完成仿真、综合实现、bitstream 生成和实物上板验证。

## 当前结论

更新时间：2026-07-04

| 类别 | 推荐路线 | 状态 | 关键指标 |
| --- | --- | --- | --- |
| 当前最快路线 | `routes_ultra/V30_dual_mcu_real_300` | 仿真 PASS，300 MHz bitstream 已生成，未上板 | `cnt_test=149`，理论时间约 `0.497 us`，WNS `+0.021 ns`，DSP 0 |
| 当前最快单核路线 | `routes_ultra/V31_single_core_final_tune_300` | 仿真 PASS，300 MHz bitstream 已生成，未上板 | `cnt_test=169`，理论时间约 `0.563 us`，WNS `+0.181 ns`，DSP 0 |
| 32 位合规展示路线 | `routes_ultra/V36_arm32_compliance_300` | 仿真 PASS，300 MHz bitstream 已生成，未上板 | 32-bit 指令字，32-bit RF/ALU/WB，`cnt_test=169`，WNS `+0.157 ns`，DSP 0 |
| 已上板 Ultra 主线 | `routes_ultra/V22b_fast_mul2_300` | 已完成实物验证 | `cnt_test=173`，300 MHz 理论时间约 `0.577 us` |
| Route A 稳定上板路线 | `routesA/speed_v7_q7_narrow_mul` | 已完成 130 MHz PLL 实物验证 | `cnt_test=157`，理论时间约 `1.208 us`，DSP 0 |

目标 FPGA 以课件 `materials/source_docs/Lab1.pdf` 为准：`XC7K160T-2FFG676-I`，Vivado part 使用 `xc7k160tffg676-2`。正式统计口径为关闭 ILA、`flatten_hierarchy=none`、`max_dsp=0`，资源统计以 post-implementation 报告为准。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `materials/` | 课程资料、K7EDAEVAL 引脚表、官方输入输出样例和原始文档归档 |
| `docs/` | 上板、交接、报告摘要和调试说明 |
| `routesA/` | 路线 A 的稳定候选、Vivado 矩阵和 130 MHz 上板资料 |
| `routesB/` | 路线 B 的 B1 到 B4 候选方案，保留独立工程和中文说明 |
| `routes_ultra/` | 300 MHz 极限优化路线，包含 V19 到 V31 的迭代记录和结果榜 |
| `RESULTS.md` | 当前速度榜、效率榜、推荐路线和风险说明 |
| `WINDOWS_CODEX_HANDOFF.md` | Windows + Vivado + Codex 环境继续调试的操作清单 |

## 推荐阅读顺序

1. `RESULTS.md`：先看当前排行榜、推荐上板路线和不建议继续投入的路线。
2. `routes_ultra/README.md`：查看 300 MHz 极限路线的完整迭代状态，重点看 V30、V31、V36、V22b。
3. `docs/上板与交接指南.md`：查看 bitstream、ILA、上板观察信号和交接步骤。
4. `routesA/README.md`：理解稳定 Route A 的来源、验证状态和 130 MHz 板级结果。
5. `materials/README.md`：确认官方样例、板卡资料和实验约束。

## 快速回归

### Route A 本地回归

需要 Python、Icarus Verilog，并确保 `iverilog`、`vvp` 在 PATH 中：

```powershell
py routesA\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

该命令会检查 Route A 的主要稳定路线，包括 `speed_v6`、`speed_v7`、`speed_v7b`、`speed_v7c`。

### Ultra V30 回归

```powershell
cd routes_ultra\V30_dual_mcu_real_300\mcu_fft_v30_dual_mcu_real_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

### Ultra V31 回归

```powershell
cd routes_ultra\V31_single_core_final_tune_300\mcu_fft_v31_single_core_final_tune_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

## Vivado 生成

本机 Vivado 路径：

```text
D:\vivado\2025.2\Vivado\bin\vivado.bat
```

Ultra 路线生成无 ILA bitstream：

```powershell
cd routes_ultra\V30_dual_mcu_real_300\mcu_fft_v30_dual_mcu_real_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

V31 可将路径替换为：

```powershell
cd routes_ultra\V31_single_core_final_tune_300\mcu_fft_v31_single_core_final_tune_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

Route A 稳定路线生成 bitstream：

```powershell
cd routesA\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ../../vivado/run_board_bitstream.tcl
```

## 上板建议

- 需要课堂展示且优先稳妥：使用已实物验证的 `routes_ultra/V22b_fast_mul2_300` 或 Route A 的 `speed_v7_q7_narrow_mul`。
- 需要回应老师“32 位机器码和架构位宽”检查：使用 `routes_ultra/V36_arm32_compliance_300`，并展示其中的 `COMPLIANCE_CHECK.md`。
- 需要冲击当前最快成绩：优先尝试 `routes_ultra/V30_dual_mcu_real_300`，但该路线 WNS 余量只有 `+0.021 ns`，建议先用 ILA 版本确认 `done`、`verify_we`、`verify_addr`、`verify_vector_out` 和 `cnt_test`。
- 需要更稳的 300 MHz 单核候选：使用 `routes_ultra/V31_single_core_final_tune_300`，时序余量比 V30 更宽。
- 不建议作为最终展示路线：V24、V27a、V27b，因为 300 MHz timing 未通过或风险明显。

首次上板重点观察：

- `done` 是否拉高。
- `verify_we` 是否产生 16 次有效写入。
- 最后写地址是否为 15。
- `cnt_test` 是否接近路线文档中的记录值。
- `verify_vector_out` 是否与 `mem/FFT_output.coe` 一致。

## 结果文件

常用结果入口：

- `RESULTS.md`
- `routes_ultra/results/ultra_summary.csv`
- `routes_ultra/README.md`
- `routesA/speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`
- `routesA/speed_v8_route_a_vivado_matrix/results/speed_leaderboard.csv`
- `routesA/speed_v8_route_a_vivado_matrix/results/efficiency_leaderboard.csv`

## 协作约定

- GitHub 远端使用 SSH：`git@github.com:trivial0930/MCU.git`。
- 中文文档统一使用 UTF-8 编码。
- `output/`、Vivado 工程缓存、`.Xil/`、`build/` 等生成物不提交。
- 提交到 GitHub 的内容应优先保留源码、脚本、关键报告、榜单 CSV/Markdown 和可复现实验命令。
