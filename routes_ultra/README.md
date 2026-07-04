# routes_ultra：300 MHz 极限优化路线

## 2026-07-05 V53 更新

新增 `V53_quad_output_owner_300/mcu_fft_v53_quad_output_owner_300`。该路线从 V45 复制，改为四个完整 MCU core 的输出归属拆分，并通过 verify RAM bank 化、关闭 Core2/Core3 shared RAM 写口、aligned-base memory offset 快路径收敛 300MHz 时序。最终官方样例 + 20 组随机 PASS，`cnt_test=72`，300MHz no-ILA WNS/TNS 为 `+0.089 ns / 0.000 ns`，LUT/FF/DSP/BRAM 为 `5002 / 3718 / 0 / 0`。V53 现在是最快 no-ILA 候选路线；V45 仍是最快已上板路线。

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频路线。正式统计均使用 no-ILA bitstream、`flatten_hierarchy=none`、`max_dsp=0`，并以 post-implementation 报告为准。

## 统一口径

- 板载输入时钟：50 MHz。
- MCU 工作时钟：`board_top.v` 中 `PLLE2_BASE` 生成 300 MHz。
- 300 MHz 判断依据：timing report 中 `clkout_raw` 周期 3.333 ns，且 WNS/TNS 非负。
- 回归：官方样例 + 20 组随机输入。
- `cnt_test`：从有效输入读取开始，到最后一次可信 verify 输出写入完成。

## 最新结论

- 当前最快合规且已上板路线：`V45_stage2_wait_reduce_300`，`cnt_test=85`，300 MHz，WNS `+0.091 ns`，DSP 0。
- V46 Stage1 最小迁移结论：`V46_stage1_split_dual_mcu_300` 功能 PASS 且 300 MHz timing-clean，但合法最优仍为 `cnt_test=85`，没有超过 V45，不建议替代主线。
- 稳定回退上板路线：`V42_v34_board_verified_300`，`cnt_test=88`，300 MHz，WNS `+0.056 ns`，DSP 0。
- 高频扫频结论：`V43_high_freq_sweep_320_350` 证明 320 MHz 以上当前结构时序不闭合，300 MHz 是可信展示频点。
- 稳定化结论：`V44_v34_retime_stable_300` 最优 WNS `+0.069 ns`，小幅优于 V42，但不足以替代 V45。
- 最终证据包：`V49_final_board_evidence_package` 汇总速度、资源、合规、上板和风险材料。
- Core1 参与中间计算证明路线：`V33_dual_mcu_compute_split_300`，Core1 执行 Stage2 `(5,7,W2)`，`cnt_test=135`。
- 当前最快单核路线：`V31_single_core_final_tune_300`，`cnt_test=169`。
- 当前 32 位合规展示路线：`V36_arm32_compliance_300`，`cnt_test=169`。
- Ultra 低风险已上板保底：`V22b_fast_mul2_300`，`cnt_test=173`。
- V27a/V27b 虽然功能速度快，但 300 MHz timing 失败，不作为主线。

## 路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V19 | `V19_pipeline_300/mcu_fft_v19_pipeline_300` | issue/execute/writeback 流水，顺序移位 MUL | 300 MHz timing-clean |
| V22b | `V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300` | 每拍处理 4 bit multiplier | 已上板低风险保底 |
| V30 | `V30_dual_mcu_real_300/mcu_fft_v30_dual_mcu_real_300` | Core1 写后半 verify 输出 | `cnt_test=149`，旧最快双核路线 |
| V31 | `V31_single_core_final_tune_300/mcu_fft_v31_single_core_final_tune_300` | 单核 W2 蝶形直接改写 | `cnt_test=169`，最快单核 |
| V33 | `V33_dual_mcu_compute_split_300/mcu_fft_v33_dual_mcu_compute_split_300` | Core1 计算 Stage2 `(5,7,W2)`，恢复 32-bit 数据通路 | `cnt_test=135`，300 MHz PASS |
| V34 | `V34_dual_mcu_schedule_300/mcu_fft_v34_dual_mcu_schedule_300` | 在 V33 基础上压缩 Core1 Stage3 等待到 23 | `cnt_test=88`，历史最快已上板路线，已由 V42 固化证据 |
| V36 | `V36_arm32_compliance_300/mcu_fft_v36_arm32_compliance_300` | 32-bit 指令字、RF/ALU/WB 合规展示 | `cnt_test=169` |
| V37 | `V37_dual_mcu_v34_stable_300/mcu_fft_v37_dual_mcu_v34_stable_300` | V34 等价复现和更强实现策略实验 | `cnt_test=88`，未超过 V34 |
| V38 | `V38_dual_mcu_stage2_wait_reduce_300/mcu_fft_v38_dual_mcu_stage2_wait_reduce_300` | 降低 Core1 Stage2 等待，并延后最后 addr15 写回对齐停表 | `cnt_test=85`，V45 的前身路线 |
| V42 | `V42_v34_board_verified_300/mcu_fft_v42_v34_board_verified_300` | 固化 V34 已上板证据，补充反汇编、opcode 和 verify 写回材料 | `cnt_test=88`，稳定回退入口 |
| V43 | `V43_high_freq_sweep_320_350/mcu_fft_v43_high_freq_sweep_320_350` | 在 V42 基础上扫 320/333.333/340/350/360 MHz | 320 MHz 以上时序失败或 PLL VCO 越界 |
| V44 | `V44_v34_retime_stable_300/mcu_fft_v44_v34_retime_stable_300` | post-route physopt、netdelay high、retiming 稳定化尝试 | 最优 WNS `+0.069 ns` |
| V45 | `V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` | 将 V38 的 Stage2 wait reduce 最快点正式化，并完成上板验证 | `cnt_test=85`，当前最快已上板路线 |
| V46 | `V46_stage1_split_dual_mcu_300/mcu_fft_v46_stage1_split_dual_mcu_300` | Core1 迁移 Stage1 下半支路，普通 shared RAM 转交 raw 输入 | `cnt_test=85`，无速度收益，负结果保留 |
| V49 | `V49_final_board_evidence_package` | 汇总 V45/V42/V43/V44 的最终答辩证据包 | 用于展示和交接，不是独立 RTL 路线 |

## 当前速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V45_stage2_wait_reduce_300 | PASS，已上板验证 | 85 | 300 MHz | 0.283 us | +0.091 ns | 2228 | 1619 | 0 |
| 1 | V46_stage1_split_dual_mcu_300 | PASS，无速度收益 | 85 | 300 MHz | 0.283 us | +0.029 ns | 2231 | 1629 | 0 |
| 2 | V42_v34_board_verified_300 | PASS，已上板证据固化 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2228 | 1615 | 0 |
| 2 | V37_dual_mcu_v34_stable_300 | PASS，未上板 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2226 | 1618 | 0 |
| 4 | V33_dual_mcu_compute_split_300 | PASS，未上板 | 135 | 300 MHz | 0.450 us | +0.034 ns | 2228 | 1616 | 0 |
| 5 | V30_dual_mcu_real_300 | PASS，未上板 | 149 | 300 MHz | 0.497 us | +0.021 ns | 2076 | 1318 | 0 |
| 6 | V31_single_core_final_tune_300 | PASS，未上板 | 169 | 300 MHz | 0.563 us | +0.181 ns | 1053 | 675 | 0 |
| 6 | V36_arm32_compliance_300 | PASS，合规展示 | 169 | 300 MHz | 0.563 us | +0.157 ns | 1213 | 822 | 0 |
| 8 | V26_scheduled_mul2_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 8 | V28_branch_reduce_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 10 | V22b_fast_mul2_300 | PASS，已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |

## 常用命令

V45 回归：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V45 no-ILA Vivado 实现：

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

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v22b_fast_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v30_dual_mcu_real_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v31_single_core_final_tune_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v33_dual_mcu_compute_split_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v36_arm32_compliance_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v42_v34_board_verified_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit
```

V27a/V27b 和 V24 会生成 bitstream，但 timing 未通过，不建议作为最终上板版本。
