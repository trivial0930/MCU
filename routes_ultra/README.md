# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频路线。正式统计均使用 no-ILA bitstream、`flatten_hierarchy=none`、`max_dsp=0`，并以 post-implementation 报告为准。

## 统一口径

- 板载输入时钟：50 MHz。
- MCU 工作时钟：`board_top.v` 中 `PLLE2_BASE` 生成 300 MHz。
- 300 MHz 判断依据：timing report 中 `clkout_raw` 周期 3.333 ns、频率 300.000 MHz，且 WNS/TNS 非负。
- 回归：官方样例 + 20 组随机输入。
- `cnt_test`：从有效输入读取开始，到最后一次可信 verify 输出写入完成。

## 最新结论

- 当前最快合规实现路线：`V38_dual_mcu_stage2_wait_reduce_300`，`cnt_test=85`，300 MHz，WNS `+0.091 ns`，DSP 0，尚未上板。
- 当前最快已上板验证路线：`V34_dual_mcu_schedule_300`，`cnt_test=88`，300 MHz，WNS `+0.056 ns`，DSP 0。
- Core1 参与中间计算证明路线：`V33_dual_mcu_compute_split_300`，Core1 执行 Stage2 `(5,7,W2)`，`cnt_test=135`。
- 当前最快单核路线：`V31_single_core_final_tune_300`，`cnt_test=169`。
- 当前 32 位合规展示路线：`V36_arm32_compliance_300`，`cnt_test=169`。
- Ultra 低风险已上板保底：`V22b_fast_mul2_300`，`cnt_test=173`。
- V27a/V27b 虽然功能速度快，但 300 MHz timing 失败，不作为主线。

## 路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V10 | `V10_width_reduce/mcu_fft_v10_width_reduce` | 25 bit 寄存器堆和 ALU 窄化 | 早期失败基线 |
| V11 | `V11_2stage_core/mcu_fft_v11_2stage_core` | 增加取指寄存器边界 | 早期失败基线 |
| V12 | `V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300` | 早期两周期 MUL 尝试 | 300 MHz 未过时序 |
| V13 | `V13_addr_decode_slim/mcu_fft_v13_addr_decode_slim` | 窄地址译码、IF/ID 边界、25 bit 数据通路 | 150 MHz timing-clean |
| V19 | `V19_pipeline_300/mcu_fft_v19_pipeline_300` | issue/execute/writeback 流水，顺序移位 MUL | 300 MHz timing-clean |
| V20 | `V20_forward_300/mcu_fft_v20_forward_300` | ALU/MOVI EX 前递 | 300 MHz 余量极薄 |
| V21 | `V21_forward_stable_300/mcu_fft_v21_forward_stable_300` | 拆分 forward/hazard 逻辑 | WNS 优于 V20 |
| V22a | `V22_fast_mul_300/mcu_fft_v22_fast_mul_300` | radix-4 通用 Q7 MUL | `cnt_test=181` |
| V22b | `V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300` | 每拍处理 4 bit multiplier | 已上板低风险保底 |
| V24 | `V24_load_forward_300/mcu_fft_v24_load_forward_300` | test_ROM LDR 前递 | 功能 PASS，时序 FAIL |
| V26 | `V26_scheduled_mul2_300/mcu_fft_v26_scheduled_mul2_300` | 输出基址初始化前移，R14 临时寄存器 | `cnt_test=172` |
| V27a | `V27_mul_explore_300/V27a_mul1_lut_300/mcu_fft_v27a_mul1_lut_300` | 单拍通用 LUT Q7 MUL | 功能 PASS，时序 FAIL |
| V27b | `V27_mul_explore_300/V27b_hybrid_mul_300/mcu_fft_v27b_hybrid_mul_300` | 通用 small-constant fast path | 功能 PASS，时序 FAIL |
| V28 | `V28_branch_reduce_300/mcu_fft_v28_branch_reduce_300` | branch/HALT/输出开销检查 | `cnt_test=172` |
| V29 | `V29_dual_mcu_300/mcu_fft_v29_dual_mcu_300` | 双完整 MCU Phase 1 骨架 | 300 MHz PASS，但无加速 |
| V30 | `V30_dual_mcu_real_300/mcu_fft_v30_dual_mcu_real_300` | Core1 写后半 verify 输出 | `cnt_test=149`，旧最快路线 |
| V31 | `V31_single_core_final_tune_300/mcu_fft_v31_single_core_final_tune_300` | 单核 W2 蝶形直接改写 | `cnt_test=169`，最快单核 |
| V33 | `V33_dual_mcu_compute_split_300/mcu_fft_v33_dual_mcu_compute_split_300` | Core1 计算 Stage2 `(5,7,W2)`，恢复 32-bit 数据通路 | `cnt_test=135`，300 MHz PASS |
| V34 | `V34_dual_mcu_schedule_300/mcu_fft_v34_dual_mcu_schedule_300` | 在 V33 基础上压缩 Core1 Stage3 等待到 23 | `cnt_test=88`，当前最快且已上板 |
| V36 | `V36_arm32_compliance_300/mcu_fft_v36_arm32_compliance_300` | 32-bit 指令字、RF/ALU/WB 合规展示 | `cnt_test=169` |
| V37 | `V37_dual_mcu_v34_stable_300/mcu_fft_v37_dual_mcu_v34_stable_300` | V34 等价复现和更强实现策略实验 | `cnt_test=88`，未超过 V34 |
| V38 | `V38_dual_mcu_stage2_wait_reduce_300/mcu_fft_v38_dual_mcu_stage2_wait_reduce_300` | 降低 Core1 Stage2 等待，并延后最后 addr15 写回对齐停表 | `cnt_test=85`，当前最快实现 |

## 当前速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V38_dual_mcu_stage2_wait_reduce_300 | PASS，未上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 2228 | 1619 | 0 |
| 2 | V34_dual_mcu_schedule_300 | PASS，已上板验证 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2228 | 1615 | 0 |
| 2 | V37_dual_mcu_v34_stable_300 | PASS，未上板 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2226 | 1618 | 0 |
| 4 | V33_dual_mcu_compute_split_300 | PASS，未上板 | 135 | 300 MHz | 0.450 us | +0.034 ns | 2228 | 1616 | 0 |
| 5 | V30_dual_mcu_real_300 | PASS，未上板 | 149 | 300 MHz | 0.497 us | +0.021 ns | 2076 | 1318 | 0 |
| 6 | V31_single_core_final_tune_300 | PASS，未上板 | 169 | 300 MHz | 0.563 us | +0.181 ns | 1053 | 675 | 0 |
| 6 | V36_arm32_compliance_300 | PASS，合规展示 | 169 | 300 MHz | 0.563 us | +0.157 ns | 1213 | 822 | 0 |
| 8 | V26_scheduled_mul2_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 8 | V28_branch_reduce_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 10 | V22b_fast_mul2_300 | PASS，已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |
| 11 | V22_fast_mul_300 | PASS | 181 | 300 MHz | 0.603 us | +0.089 ns | 1012 | 675 | 0 |
| 12 | V21_forward_stable_300 | PASS | 197 | 300 MHz | 0.657 us | +0.031 ns | 973 | 675 | 0 |
| 12 | V20_forward_300 | PASS | 197 | 300 MHz | 0.657 us | +0.004 ns | 989 | 675 | 0 |
| 14 | V19_pipeline_300 | PASS | 204 | 300 MHz | 0.680 us | +0.121 ns | 860 | 675 | 0 |
| - | V27b_hybrid_mul_300 | 功能 PASS，时序 FAIL | 157 | 300 MHz | 0.523 us | -1.052 ns | 1361 | 698 | 0 |
| - | V27a_mul1_lut_300 | 功能 PASS，时序 FAIL | 157 | 300 MHz | 0.523 us | -2.199 ns | 1203 | 648 | 0 |
| - | V24_load_forward_300 | 功能 PASS，时序 FAIL | 173 | 300 MHz | 0.577 us | -0.005 ns | 1106 | 681 | 0 |
| - | V29_dual_mcu_300 | Phase 1 骨架 PASS | 173 | 300 MHz | 0.577 us | +0.003 ns | 1679 | 915 | 0 |

## 常用命令

最快 V38 回归：

```powershell
cd routes_ultra\V38_dual_mcu_stage2_wait_reduce_300\mcu_fft_v38_dual_mcu_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V38 no-ILA Vivado 实现：

```powershell
cd routes_ultra\V38_dual_mcu_stage2_wait_reduce_300\mcu_fft_v38_dual_mcu_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v38_stable_no_ila.tcl
```

最快已上板 V34 回归：

```powershell
cd routes_ultra\V34_dual_mcu_schedule_300\mcu_fft_v34_dual_mcu_schedule_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V34 no-ILA Vivado 实现：

```powershell
cd routes_ultra\V34_dual_mcu_schedule_300\mcu_fft_v34_dual_mcu_schedule_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v22b_fast_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v30_dual_mcu_real_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v31_single_core_final_tune_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v33_dual_mcu_compute_split_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v36_arm32_compliance_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v37_dual_mcu_v34_stable_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v38_dual_mcu_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit
```

V27a/V27b 和 V24 会生成 bitstream，但 timing 未通过，不建议作为最终上板版本。
