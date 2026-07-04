# 当前结果速览

更新时间：2026-07-05

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- Ultra 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 中 PLLE2 生成 300 MHz，timing report 中 `clkout_raw` 周期为 3.333 ns
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源和速度统计：关闭 ILA
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：从有效输入读取开始，到最后一次可信 verify 输出写入完成

## Ultra 300 MHz 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V45_stage2_wait_reduce_300` | PASS，已上板验证 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 当前最快 no-ILA 合规实现和最快已上板路线 |
| 2 | `V42_v34_board_verified_300` | PASS，已上板证据固化 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 稳定回退路线，V34 实物验证证据固化版本 |
| 2 | `V37_dual_mcu_v34_stable_300` | PASS，未上板 | 88 | 0.293 us | +0.056 ns | 2226 | 1618 | 0 | V34 等价复现和实现策略实验 |
| 4 | `V33_dual_mcu_compute_split_300` | PASS，未上板 | 135 | 0.450 us | +0.034 ns | 2228 | 1616 | 0 | Core1 真实参与 Stage2 中间计算 |
| 5 | `V30_dual_mcu_real_300` | PASS，未上板 | 149 | 0.497 us | +0.021 ns | 2076 | 1318 | 0 | 旧双核输出拆分主线，已被 V33/V42/V45 超过 |
| 6 | `V31_single_core_final_tune_300` | PASS，未上板 | 169 | 0.563 us | +0.181 ns | 1053 | 675 | 0 | 当前最快单核路线 |
| 6 | `V36_arm32_compliance_300` | PASS，合规展示 | 169 | 0.563 us | +0.157 ns | 1213 | 822 | 0 | 32-bit 机器码/数据通路展示路线 |
| 8 | `V26_scheduled_mul2_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | 已被 V31/V33/V42/V45 超过 |
| 8 | `V28_branch_reduce_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | V31 的来源路线 |
| 10 | `V22b_fast_mul2_300` | PASS，已上板验证 | 173 | 0.577 us | +0.122 ns | 1053 | 675 | 0 | Ultra 已上板稳定备选 |
| 11 | `V22_fast_mul_300` | PASS | 181 | 0.603 us | +0.089 ns | 1012 | 675 | 0 | 被 V22b/V26/V28 超过 |
| 12 | `V21_forward_stable_300` | PASS | 197 | 0.657 us | +0.031 ns | 973 | 675 | 0 | 稳定前递版本 |
| 12 | `V20_forward_300` | PASS | 197 | 0.657 us | +0.004 ns | 989 | 675 | 0 | 时序余量很薄 |
| 14 | `V19_pipeline_300` | PASS | 204 | 0.680 us | +0.121 ns | 860 | 675 | 0 | 300 MHz 稳健基线 |
| - | `V27b_hybrid_mul_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -1.052 ns | 1361 | 698 | 0 | 不可作为主线 |
| - | `V27a_mul1_lut_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -2.199 ns | 1203 | 648 | 0 | 单拍通用乘法过重 |
| - | `V24_load_forward_300` | 功能 PASS，时序 FAIL | 173 | 0.577 us | -0.005 ns | 1106 | 681 | 0 | 负结果 |
| - | `V29_dual_mcu_300` | Phase 1 骨架 PASS | 173 | 0.577 us | +0.003 ns | 1679 | 915 | 0 | 双核骨架，无速度收益 |

完整明细见 `routes_ultra/results/ultra_summary.csv` 和 `routes_ultra/README.md`。

## 本轮关键结论

V45：

- 根据 V42/V43/V44 结果，正式固化 Stage2 wait reduce 路线。
- 官方样例 + 20 组随机 PASS。
- 300 MHz no-ILA bitstream 生成成功，`cnt_test=85`，WNS `+0.091 ns`，DSP 0。
- no-ILA 下载成功，硬件目标为 `localhost:3121/xilinx_tcf/Digilent/210251A08870`，器件识别为 `xc7k160t_0`。
- ILA 调试抓到 16 次 verify 写回，地址 0..15 全覆盖，输出与 `FFT_output.coe` 完全一致。
- ILA 比对结果：`write_count=16`、`unique_addr_count=16`、`last_write_addr=15`、`final_done_cnt_test=85`、`compare_status=PASS`。
- ILA 版由于调试核引入额外负载，WNS 为 -0.068 ns，只作为功能抓波证据；正式成绩仍以 no-ILA timing-clean 报告为准。
- 上板验证结束后已重新下载 no-ILA bitstream。

V42：

- 从已上板验证的 V34 固化为正式证据路线。
- 官方样例 + 20 组随机 PASS。
- 300 MHz no-ILA bitstream 生成成功，WNS `+0.056 ns`，DSP 0。
- `cnt_test=88`，保留为 V45 之外的低风险回退路线。

V43：

- 在 V42 基础上做 320/333.333/340/350/360 MHz 高频扫频。
- 300 MHz timing-clean；320 MHz、333.333 MHz、350 MHz 均可生成 bitstream 但 WNS 为负。
- 340 MHz、360 MHz 因 PLLE2 VCO 超出允许范围被脚本主动阻断。
- 结论：当前结构不建议直接冲 320 MHz 以上，300 MHz 仍是可信展示频点。

V44：

- 在 V42 基础上尝试 post-route physopt、netdelay high、retiming 三种稳定化实现策略。
- 最优 `retiming_try`：WNS `+0.069 ns`，LUT 2224，FF 1608，DSP 0。
- 相比 V42 的 `+0.056 ns` 有小幅改善，但没有达到替代阈值。

## 上板建议

- 需要最快实现和最快已上板成绩：优先使用 `V45_stage2_wait_reduce_300`。
- 需要稳妥回退：使用已固化上板证据的 `V42_v34_board_verified_300`。
- 需要最低风险且结构较简单：继续使用已上板的 `V22b_fast_mul2_300`。
- 需要回应老师“32 位机器码和架构位宽”：使用 `V36_arm32_compliance_300`，或展示 V33/V34/V45 的 32-bit 指令和普通 MCU 数据通路说明。
- 需要完整答辩资料：使用 `V49_final_board_evidence_package`。
- 暂不推荐：V24、V27a、V27b，因为 300 MHz timing 未通过。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
