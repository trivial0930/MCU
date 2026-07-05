# MCU FFT 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU FFT 项目。目标是在目标板卡 `xc7k160tffg676-2` 上，使用普通 MCU 指令完成 8 点定点复数 FFT，并保留可复现的仿真、综合、实现、bitstream、上板验证和中文说明材料。

## 最新状态

更新时间：2026-07-05

| 项目 | 当前结论 |
| --- | --- |
| 当前最快 no-ILA 实现候选 | `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300` |
| V59 性能 | `cnt_test=49`，300 MHz 理论时间约 `0.163 us` |
| V59 Vivado | 300 MHz no-ILA bitstream 已生成，WNS/TNS = `+0.095 ns / 0.000 ns` |
| V59 资源 | LUT 8677，FF 6451，DSP 0，BRAM 0 |
| 当前最快已上板验证路线 | `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300` |
| V54 上板结果 | `cnt_test=59`，300 MHz，ILA 抓取 16 次 verify 写回全覆盖，输出比对 PASS |
| 低资源双核备份 | `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300`，`cnt_test=85`，已上板 |

V59 是本轮 V56-V59 迭代得到的最快 no-ILA bitstream 候选；V54 仍是最快的已上板验证版本。如果需要课堂展示的最高确定性，优先带 V54；如果要展示最新速度突破，带 V59 的仿真、Vivado 和 bitstream 证据。

## 合规边界

当前主线坚持以下约束：

- 不新增 FFT engine、butterfly_unit、fft_stage_unit、twiddle_engine、DMA controller 或 coprocessor。
- 不新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等 FFT/复数/蝶形专用指令。
- 每个 core 均保留完整 MCU 结构，包括 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 输入读取、计算和 verify 写回均通过普通 `LDR/ADD/SUB/MUL/STR` 等指令完成。
- DSP 使用量必须为 0。
- `cnt_test` 保持全系统 wall-clock 口径，不能通过少写 verify 或提前停表制造假加速。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `materials/` | 课程资料、板卡资料、官方输入输出样例和原始文档归档 |
| `docs/` | 上板、交接、报告摘要和调试说明 |
| `routesA/` | 路线 A 稳定候选、Vivado 矩阵和 130 MHz 上板资料 |
| `routesB/` | 路线 B 的 B1 到 B4 候选方案和中文说明 |
| `routes_ultra/` | 300 MHz 极限优化路线，当前重点为 V54、V56-V59 |
| `RESULTS.md` | 当前速度榜、效率榜、推荐路线和风险说明 |
| `WINDOWS_CODEX_HANDOFF.md` | Windows + Vivado + Codex 环境继续调试清单 |

## 常用复现命令

V59 功能回归：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V59 300 MHz no-ILA 实现：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v59_no_ila.tcl -tclargs 300
```

V54 已上板路线回归：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

## 结果入口

- `RESULTS.md`
- `routes_ultra/README.md`
- `routes_ultra/results/ultra_summary.csv`
- `routes_ultra/results/v56_v59_iteration_summary.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/ROUTE_NOTES.md`
- `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300/board_validation/`

## 协作约定

- GitHub 远端使用 SSH：`git@github.com:trivial0930/MCU.git`。
- 中文文档统一使用 UTF-8 编码。
- `build/`、`.Xil/`、Vivado 工程缓存、随机临时输出和 bitstream 大文件不提交。
- 提交到 GitHub 的内容优先保留源码、脚本、关键报告、榜单 CSV/Markdown 和可复现实验命令。
