# 当前结果速览

更新时间：2026-07-04

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- Ultra 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 中 PLLE2 生成 300 MHz，timing report 中 `clkout_raw` 周期为 3.333 ns
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/速度统计：关闭 ILA
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：从有效输入读取开始，到最后一次可信 verify 输出写入完成

## Ultra 300 MHz 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V34_dual_mcu_schedule_300` | PASS，未上板 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 当前最快合规路线，Core1 中间计算 + 调度压缩 |
| 2 | `V33_dual_mcu_compute_split_300` | PASS，未上板 | 135 | 0.450 us | +0.034 ns | 2228 | 1616 | 0 | Core1 真实参与 Stage2 中间计算 |
| 3 | `V30_dual_mcu_real_300` | PASS，未上板 | 149 | 0.497 us | +0.021 ns | 2076 | 1318 | 0 | 旧双核输出拆分主线，已被 V33/V34 超过 |
| 4 | `V31_single_core_final_tune_300` | PASS，未上板 | 169 | 0.563 us | +0.181 ns | 1053 | 675 | 0 | 当前最快单核路线 |
| 4 | `V36_arm32_compliance_300` | PASS，合规展示 | 169 | 0.563 us | +0.157 ns | 1213 | 822 | 0 | 32-bit 机器码/数据通路展示路线 |
| 6 | `V26_scheduled_mul2_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | 已被 V31/V33/V34 超过 |
| 6 | `V28_branch_reduce_300` | PASS，未上板 | 172 | 0.573 us | +0.067 ns | 1050 | 675 | 0 | V31 的来源路线 |
| 8 | `V22b_fast_mul2_300` | PASS，已上板验证 | 173 | 0.577 us | +0.122 ns | 1053 | 675 | 0 | 当前已上板主线 |
| 9 | `V22_fast_mul_300` | PASS | 181 | 0.603 us | +0.089 ns | 1012 | 675 | 0 | 被 V22b/V26/V28 超过 |
| 10 | `V21_forward_stable_300` | PASS | 197 | 0.657 us | +0.031 ns | 973 | 675 | 0 | 稳定前递版本 |
| 10 | `V20_forward_300` | PASS | 197 | 0.657 us | +0.004 ns | 989 | 675 | 0 | 时序余量很薄 |
| 12 | `V19_pipeline_300` | PASS | 204 | 0.680 us | +0.121 ns | 860 | 675 | 0 | 300 MHz 稳健基线 |
| - | `V27b_hybrid_mul_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -1.052 ns | 1361 | 698 | 0 | 不可作为主线 |
| - | `V27a_mul1_lut_300` | 功能 PASS，时序 FAIL | 157 | 0.523 us | -2.199 ns | 1203 | 648 | 0 | 单拍通用乘法过重 |
| - | `V24_load_forward_300` | 功能 PASS，时序 FAIL | 173 | 0.577 us | -0.005 ns | 1106 | 681 | 0 | 负结果 |
| - | `V29_dual_mcu_300` | Phase 1 骨架 PASS | 173 | 0.577 us | +0.003 ns | 1679 | 915 | 0 | 双核骨架，无速度收益 |

完整明细见 `routes_ultra/results/ultra_summary.csv` 和 `routes_ultra/README.md`。

## 本轮新增结果

V33：

- 从 V30 继续，跳过 V32。
- Core1 执行 Stage2 `(5,7,W2)`，不再只是后半输出搬运。
- 官方样例 + 20 组随机 PASS。
- `cnt_test=135`，300 MHz no-ILA WNS `+0.034 ns`。

V34：

- 从 V33 继续，不改变计算分工，只压缩 Core1 Stage3 前等待。
- `CORE1_WAIT_STAGE3_NOP` 从 70 降到 23。
- `stage3_wait=23` 是本轮找到的最小安全边界；更小值会出现 addr15 过早或 verify 写入不足的问题。
- 官方样例 + 20 组随机 PASS。
- `cnt_test=88`，300 MHz no-ILA WNS `+0.056 ns`，DSP 0。

## 上板建议

- 需要最快成绩：优先尝试 `V34_dual_mcu_schedule_300`，先做 ILA 观察，再下载 no-ILA 正式版本统计。
- 需要最低风险：继续使用已上板的 `V22b_fast_mul2_300`。
- 需要回应老师“32 位机器码和架构位宽”：使用 `V36_arm32_compliance_300`，或展示 V33/V34 的 32-bit RF/ALU/WB 修改。
- 暂不推荐：V24、V27a、V27b，因为 300 MHz timing 未通过。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
