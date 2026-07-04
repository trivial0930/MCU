# 当前结果速览

更新时间：2026-07-04

## 最终口径

- 目标器件：`xc7k160tffg676-2`
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/速度统计：关闭 ILA
- Ultra 路线 MCU 频率：300 MHz
- `cnt_test`：从第一次有效读取输入开始，到最后一次 verify 输出写入完成

## Ultra 300 MHz 最新结果

| 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `V30_dual_mcu_real_300` | PASS，未上板 | 149 | 0.497 us | +0.021 ns | 2076 | 1318 | 0 | 当前最快，Core1 真实参与输出 |
| `V31_single_core_final_tune_300` | PASS，未上板 | 169 | 0.563 us | +0.181 ns | 1053 | 675 | 0 | 当前最快单核路线 |
| `V36_arm32_compliance_300` | PASS，未上板 | 169 | 0.563 us | +0.157 ns | 1213 | 822 | 0 | 32 位机器码/32 位数据通路合规展示路线 |
| `V26_scheduled_mul2_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | 已被 V31 超过 |
| `V28_branch_reduce_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | V31 的来源路线 |
| `V22b_fast_mul2_300` | PASS，已上板验证 | 173 | 0.577 us | +0.122 ns | 1053 | 675 | 0 | 当前已上板主线 |
| `V22_fast_mul_300` | PASS | 181 | 0.603 us | +0.089 ns | 1012 | 675 | 0 | 被 V22b/V26/V28 超过 |
| `V21_forward_stable_300` | PASS | 197 | 0.657 us | +0.031 ns | 973 | 675 | 0 | 稳定前递版本 |
| `V20_forward_300` | PASS | 197 | 0.657 us | +0.004 ns | 989 | 675 | 0 | 余量极薄 |
| `V19_pipeline_300` | PASS | 204 | 0.680 us | +0.121 ns | 860 | 675 | 0 | 300 MHz 稳健基线 |
| `V27b_hybrid_mul_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -1.052 ns | 1361 | 698 | 0 | 不能作为主线 |
| `V27a_mul1_lut_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -2.199 ns | 1203 | 648 | 0 | 单拍通用乘法过重 |
| `V24_load_forward_300` | 功能 PASS，时序 FAIL | 173 | 0.577 us | -0.005 ns | 1106 | 681 | 0 | 负结果 |
| `V29_dual_mcu_300` | Phase 1 骨架 PASS | 173 | 0.577 us | +0.003 ns | 1679 | 915 | 0 | 可继续开发，不是性能主线 |

完整明细见 `routes_ultra/results/ultra_summary.csv` 和 `routes_ultra/README.md`。

## 上板建议

- 需要“已验证能上板”的展示：继续使用 `routes_ultra/V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300`。
- 需要“符合老师 32 位机器码和架构位宽检查”的展示：使用 `routes_ultra/V36_arm32_compliance_300/mcu_fft_v36_arm32_compliance_300`。
- 需要“当前最快成绩”：优先尝试 `V30_dual_mcu_real_300`，但 WNS 余量较薄，建议先按 V22b 的 ILA 方法补一次实物验证。
- 需要“当前最快单核成绩”：优先尝试 `V31_single_core_final_tune_300`。
- 不建议上板：V27a/V27b/V24，原因是 300 MHz timing 未通过。
- V29 当前只用于双核后续开发，不建议作为最终演示速度路线。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
