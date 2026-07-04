# 当前结果速览

更新时间：2026-07-04

## 最终口径

- 目标器件：`xc7k160tffg676-2`
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/速度统计：关闭 ILA
- 上板调试：先使用带 ILA bitstream，确认功能后切换无 ILA bitstream
- Route A 当前实物上板时钟：`130 MHz`，由板载 50 MHz 通过 `PLLE2_BASE` 倍频得到
- Ultra 当前最高已实现时钟：`300 MHz`，见 `routes_ultra/`

## 推荐上板路线

```text
routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
```

已生成文件：

| 文件 | 用途 |
| --- | --- |
| `results/vivado_board/board_top_ila.bit` | 50 MHz 历史调试版本 |
| `results/vivado_board/board_top_no_ila.bit` | 50 MHz 历史正式版本 |
| `output/hardware_debug/routeA_130MHz_PLL_20260704/ila/board_top_130pll_ila.bit` | 130 MHz 带 ILA 验证版本，本地交付物 |
| `output/hardware_debug/routeA_130MHz_PLL_20260704/no_ila/board_top_130pll_no_ila.bit` | 130 MHz 无 ILA 正式上板版本，本地交付物 |

## Ultra 300 MHz 最新结果

`routes_ultra/` 已完成多条真正 timing-clean 的 300 MHz 路线。最新最快路线为 V22b：

| 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `V22b_fast_mul2_300` | 当前最快 300 MHz 版，2 拍通用 Q7 MUL | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |
| `V22_fast_mul_300` | 4 拍 radix-4 通用 Q7 MUL | 181 | 300 MHz | 0.603 us | +0.089 ns | 1012 | 675 | 0 |
| `V21_forward_stable_300` | V20 forward 稳健化 | 197 | 300 MHz | 0.657 us | +0.031 ns | 973 | 675 | 0 |
| `V20_forward_300` | 早期最快 300 MHz 版，余量极薄 | 197 | 300 MHz | 0.657 us | +0.004 ns | 989 | 675 | 0 |
| `V19_pipeline_300` | 已实物上板验证的 300 MHz 稳健版 | 204 | 300 MHz | 0.680 us | +0.121 ns | 860 | 675 | 0 |

以上路线均通过官方样例 + 20 组随机输入回归、Vivado 综合、实现、DRC 和 bitstream 生成，正式统计均关闭 ILA 且 DSP=0。V19 已完成实物上板验证；V22b 是新的速度主线，下一步建议做 V22b ILA 上板验证。

## 最新 130 MHz 上板结果

当前已将 `speed_v7_q7_narrow_mul` 的板级顶层从直连 `CLK_50M` 改为：

```text
CLK_50M -> PLLE2_BASE -> BUFG -> MCU clk
```

PLL 参数为 `CLKFBOUT_MULT=26`、`CLKOUT0_DIVIDE=10`，因此实际 MCU 时钟为 `50 MHz * 26 / 10 = 130 MHz`。复位逻辑同步加入 `pll_locked` 保护：`rst = ~KEY1 | ~pll_locked`。

| 项目 | 结果 |
| --- | --- |
| 实际上板时钟 | 130 MHz |
| 无 ILA post-route WNS | 0.190 ns |
| 无 ILA TNS | 0.000 ns |
| DRC | 0 Error；仅剩 `CFGBVS/CONFIG_VOLTAGE` warning |
| DSP | 0 |
| `cnt_test` | 157 |
| 测试窗口耗时 | `157 / 130 MHz = 1.208 us` |
| 上板验证 | 带 ILA 抓到 16 次写回，全部与 `FFT_output.coe` 匹配 |
| 最终板卡状态 | 已切回 130 MHz 无 ILA bitstream，`ilas_after_program=0` |

说明：带 ILA 的 130 MHz 验证版本因为插入调试核，post-route WNS 为 `-0.033 ns`，只用于抓波确认功能；正式速度/资源口径使用无 ILA 版本。

## 路线 A 速度榜

完整文件：`routesA/speed_v8_route_a_vivado_matrix/results/speed_leaderboard.csv`

| 排名 | 路线 | 最高通过频率 | WNS(ns) | LUT | FF | DSP |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 549 | 0 |
| 2 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 549 | 0 |
| 3 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 549 | 0 |
| - | `speed_v6_official_sample` | 未通过 95 MHz | -0.162 | 1704 | 549 | 0 |

## 效率榜

完整文件：`routesA/speed_v8_route_a_vivado_matrix/results/efficiency_leaderboard.csv`

| 排名 | 路线 | 目标频率 | WNS(ns) | LUT | MHz/LUT |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 0.152047 |
| 2 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 0.146232 |
| 3 | `speed_v7c_c91_shift_sub` | 120 MHz | 0.518 | 853 | 0.140680 |
| 4 | `speed_v7b_c91_shift_add` | 120 MHz | 0.525 | 873 | 0.137457 |
| 5 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 0.131846 |

## 判断建议

- 若只看资源效率，`speed_v7c_c91_shift_sub` 当前最好。
- 若更看重语义通用性和上板风险，优先使用 `speed_v7_q7_narrow_mul`；该路线已完成 130 MHz PLL 实物上板验证。
- `speed_v6_official_sample` 在 `max_dsp=0` 后 95 MHz 已不满足时序，不建议作为最终速度路线。

## 路线 B 初步结果

已基于路线 A 当前效率最优的 `speed_v7c_c91_shift_sub` 新建
`routesA/speed_v9_cycle_reduce`，实现第一版低周期优化：

| 路线 | 指令数 | cnt_test | 目标频率 | WNS(ns) | LUT | FF | DSP | 结论 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `speed_v9_cycle_reduce` | 156 | 151 | 120 MHz | 0.091 | 1194 | 549 | 0 | PASS |
| `speed_v9_cycle_reduce` | 156 | 151 | 130 MHz | -0.140 | 1210 | 549 | 0 | 未过时序 |

结论：路线 B 可以实现并通过功能回归，`cnt_test` 从路线 A v7c 的 `157`
降到 `151`。但第一版复合指令增加了 ALU 组合路径和 LUT，当前 130 MHz
未收敛；按已收敛的 120 MHz 计算，总时间约 `1.258 us`，暂时还没有超过
路线 A v7c 在 130 MHz 下的 `1.208 us`。

更详细说明见 `docs/上板与交接指南.md` 和
`routesA/speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`。
