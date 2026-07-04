# MCU FFT 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU 实验中的 8 点定点复数 FFT 任务。当前设计目标是在不直接例化 FFT IP、DSP IP、DMA、协处理器或专用 FFT 加速器的前提下，用自研轻量 MCU 执行普通指令完成 FFT 计算，并完成仿真、综合、实现、bitstream 生成和上板验证资料整理。

## 当前结论

更新时间：2026-07-05

| 类别 | 推荐路线 | 状态 | 关键指标 |
| --- | --- | --- | --- |
| 当前最快合规且已上板路线 | `routes_ultra/V45_stage2_wait_reduce_300` | 官方样例 + 20 随机 PASS，300 MHz no-ILA bitstream timing-clean，实物上板 PASS | `cnt_test=85`，理论时间约 `0.283 us`，WNS `+0.091 ns`，DSP 0 |
| 已上板保底路线 | `routes_ultra/V42_v34_board_verified_300` | V34/V42 上板证据固化，300 MHz timing-clean | `cnt_test=88`，理论时间约 `0.293 us`，WNS `+0.056 ns`，DSP 0 |
| 最终答辩证据包 | `routes_ultra/V49_final_board_evidence_package` | 汇总 V45/V42/V43/V44 的速度、资源、合规和上板材料 | V45 负责最快已上板成绩，V42 负责回退保底 |
| Core1 参与中间计算证明路线 | `routes_ultra/V33_dual_mcu_compute_split_300` | PASS，300 MHz bitstream 已生成，未上板 | Core1 执行 Stage2 `(5,7,W2)`，`cnt_test=135`，WNS `+0.034 ns`，DSP 0 |
| 已上板 Ultra 稳定备选 | `routes_ultra/V22b_fast_mul2_300` | 已完成实物验证 | `cnt_test=173`，300 MHz 理论时间约 `0.577 us` |
| 32 位合规展示备选 | `routes_ultra/V36_arm32_compliance_300` | PASS，300 MHz bitstream 已生成，未上板 | 32-bit 指令字、32-bit RF/ALU/WB，`cnt_test=169`，WNS `+0.157 ns` |
| 最快单核备选 | `routes_ultra/V31_single_core_final_tune_300` | PASS，300 MHz bitstream 已生成，未上板 | `cnt_test=169`，理论时间约 `0.563 us`，WNS `+0.181 ns` |
| Route A 稳定上板路线 | `routesA/speed_v7_q7_narrow_mul` | 已完成 130 MHz PLL 实物验证 | `cnt_test=157`，理论时间约 `1.208 us`，DSP 0 |

目标 FPGA 以课程资料为准：`XC7K160T-2FFG676-I`，Vivado part 使用 `xc7k160tffg676-2`。Ultra 路线板载输入时钟为 50 MHz，`board_top.v` 内部通过 PLLE2 生成 300 MHz MCU 时钟；正式速度和资源统计使用 no-ILA、`flatten_hierarchy=none`、`max_dsp=0`、post-implementation 报告。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `materials/` | 课程资料、板卡资料、官方输入输出样例和原始文档归档。 |
| `docs/` | 上板、交接、报告摘要和调试说明。 |
| `routesA/` | 路线 A 的稳定候选、Vivado 矩阵和 130 MHz 上板资料。 |
| `routesB/` | 路线 B 的 B1 到 B4 候选方案和中文说明。 |
| `routes_ultra/` | 300 MHz 极限优化路线，当前重点为 V45/V49，并保留 V42/V43/V44/V33/V36/V22b 历史依据。 |
| `RESULTS.md` | 当前速度榜、效率榜、推荐路线和风险说明。 |
| `WINDOWS_CODEX_HANDOFF.md` | Windows + Vivado + Codex 环境继续调试清单。 |

## 常用复现命令

V45 回归：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V45 no-ILA bitstream：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v45_stable_no_ila.tcl
```

V45 上板验证：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v45_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v45_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v45_ila_verify_we.tcl
py board_validation\compare_v45_ila_capture.py
```

V42 回退路线回归：

```powershell
cd routes_ultra\V42_v34_board_verified_300\mcu_fft_v42_v34_board_verified_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

Route A 本地回归：

```powershell
py routesA\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

## 上板建议

- 想展示目前最快成绩：使用 `routes_ultra/V45_stage2_wait_reduce_300` 的 no-ILA bitstream，板上验证已 PASS。
- 想展示最低风险回退：使用已固化上板证据的 `routes_ultra/V42_v34_board_verified_300`。
- 想展示已经上过板且结构更简单的 Ultra 备选：使用 `routes_ultra/V22b_fast_mul2_300`。
- 想回应老师“32 位机器码和架构位宽”检查：使用 `routes_ultra/V36_arm32_compliance_300`，或说明 V33/V34/V45 均保留 32-bit 指令与普通 MCU 数据通路口径。
- 想给队友或老师快速交付材料：使用 `routes_ultra/V49_final_board_evidence_package`。
- 不建议作为最终展示路线：V24、V27a、V27b，因为 300 MHz timing 未通过或风险明显。

首轮上板重点观察：

- `done` 是否拉高。
- `verify_we` 是否产生 16 次有效写入。
- 最后写地址是否为 15。
- `cnt_test` 是否为对应路线文档中的记录值。
- `verify_vector_out` 是否与 `mem/FFT_output.coe` 一致。

## 结果入口

- `RESULTS.md`
- `routes_ultra/README.md`
- `routes_ultra/results/ultra_summary.csv`
- `routes_ultra/V49_final_board_evidence_package/FINAL_REPORT.md`
- `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300/BOARD_VALIDATION.md`
- `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300/ROUTE_NOTES.md`
- `routes_ultra/V42_v34_board_verified_300/mcu_fft_v42_v34_board_verified_300/ROUTE_NOTES.md`

## 协作约定

- GitHub 远端使用 SSH：`git@github.com:trivial0930/MCU.git`。
- 中文文档统一使用 UTF-8 编码。
- `output/`、Vivado 工程缓存、`.Xil/`、`build/` 等生成物不提交。
- 提交到 GitHub 的内容优先保留源码、脚本、关键报告、榜单 CSV/Markdown 和可复现实验命令。
