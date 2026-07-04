# 当前结果速览

更新时间：2026-07-05

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- Ultra 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 内部 PLLE2 生成 300 MHz
- 正式资源和速度统计：关闭 ILA，`flatten_hierarchy=none`，`max_dsp=0`
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：从有效输入读取开始，到最后一次可信 verify 输出写入完成

## Ultra 300 MHz 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V54_octa_output_owner_300` | PASS，已上板验证 | 59 | 0.197 us | +0.095 ns | 8733 | 6476 | 0 | 当前最快 no-ILA 合规实测路线 |
| 2 | `V53_quad_output_owner_300` | PASS，bitstream 已生成，待上板 | 72 | 0.240 us | +0.089 ns | 5002 | 3718 | 0 | 四核输出归属路线，已被 V54 超过 |
| 3 | `V45_stage2_wait_reduce_300` | PASS，已上板验证 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 双核已上板备份路线 |
| 3 | `V46_stage1_split_dual_mcu_300` | PASS，无速度收益 | 85 | 0.283 us | +0.029 ns | 2231 | 1629 | 0 | Core1 迁移 Stage1 的负结果保留 |
| 5 | `V42_v34_board_verified_300` | PASS，已上板证据固化 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 稳定回退路线 |
| 6 | `V33_dual_mcu_compute_split_300` | PASS，未上板 | 135 | 0.450 us | +0.034 ns | 2228 | 1616 | 0 | Core1 真实参与 Stage2 中间计算 |
| 7 | `V30_dual_mcu_real_300` | PASS，未上板 | 149 | 0.497 us | +0.021 ns | 2076 | 1318 | 0 | 旧双核输出拆分路线 |
| 8 | `V31_single_core_final_tune_300` | PASS，未上板 | 169 | 0.563 us | +0.181 ns | 1053 | 675 | 0 | 当前最快单核路线 |
| 8 | `V36_arm32_compliance_300` | PASS，合规展示 | 169 | 0.563 us | +0.157 ns | 1213 | 822 | 0 | 32-bit 合规展示路线 |
| 10 | `V22b_fast_mul2_300` | PASS，已上板验证 | 173 | 0.577 us | +0.122 ns | 1053 | 675 | 0 | Ultra 已上板稳定备选 |

不推荐作为最终展示主线：`V24_load_forward_300`、`V27a_mul1_lut_300`、`V27b_hybrid_mul_300`，原因是 300 MHz timing 未通过。

## 本轮 V54 关键结论

V54 从 V53 的思路继续推进到 8 个完整 MCU core，每个 core 负责一个复数输出 X0 到 X7：

- 官方样例 + 20 组随机 PASS。
- `cnt_test=59`，比 V53 的 72 少 13 cycle，比 V45 的 85 少 26 cycle。
- 300 MHz no-ILA 实现通过：WNS/TNS = +0.095 ns / 0.000 ns，WHS/THS = +0.072 ns / 0.000 ns。
- DRC 报告 `Checks found: 0`。
- DSP=0，BRAM=0。
- 已完成板上 ILA 抓波验证：16 次 verify 写回、地址 0..15 全覆盖、最后地址 15、输出与期望完全一致，最终重新下载 no-ILA 正式 bitstream。
- V54 不增加专用 FFT 硬件，也不增加专用指令；速度收益来自输出归属拆分、test ROM 复制、verify RAM bank 化和奇数输出核内 `×91` 结果复用。

## 上板建议

- 展示最快已上板实现：使用 V54 的 no-ILA bitstream。
- 展示低资源双核备份结果：使用 V45。
- 需要稳妥回退：使用 V42/V34 固化证据路线。
- 需要回答老师合规要求：准备 V54 的 `OCTA_MCU_COMPLIANCE_REPORT.md`、`opcode_summary_all.csv` 和 `verify_writer_trace.csv`。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
