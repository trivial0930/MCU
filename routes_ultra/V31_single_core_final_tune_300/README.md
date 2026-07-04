# V31_single_core_final_tune_300

V31 是基于 V28 的单核最终微调路线。核心优化是把 W2 蝶形中的 `-real_diff` 直接改写为 `b.real-a.real`，删除 3 条 counted 窗口内的冗余 `SUB`。

| 项目 | 结果 |
| --- | ---: |
| 架构 | 单核 MCU |
| `cnt_test` | 169 |
| MCU 频率 | 300 MHz |
| 理论时间 | 0.563 us |
| WNS/TNS | +0.181 ns / 0.000 ns |
| WHS/THS | +0.101 ns / 0.000 ns |
| LUT/FF/DSP | 1053 / 675 / 0 |
| 回归 | 官方样例 + 20 随机 PASS |

建议作为新的单核速度候选。详细记录见 `mcu_fft_v31_single_core_final_tune_300/ROUTE_NOTES.md`。
