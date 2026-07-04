# V43 高频扫频报告

本报告基于 V42/V34 的 88cnt 双 MCU 路线生成。V43 不改变指令流和功能 RTL，只改变板级 PLL 输出频率并重新执行 no-ILA Vivado bitstream 实现。

## 扫频结果

| 请求频率 | 实际频率 | bitstream | WNS | WHS | LUT | FF | DSP | 理论时间(us) | 结论 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 300.000 | 300.000 | yes | 0.056 | 0.085 | 2228 | 1615 | 0 | 0.293333 | timing_clean_dsp0 |
| 320.000 | 320.000 | yes | -0.250 | 0.111 | 2250 | 1641 | 0 | 0.275000 | timing_failed_bitstream_generated_dsp0 |
| 333.000 | 333.333 | yes | -0.143 | 0.141 | 2298 | 1648 | 0 | 0.264000 | timing_failed_bitstream_generated_dsp0 |
| 340.000 | 340.000 | no |  |  |  |  |  | 0.258824 | blocked_plle2_vco_range_1700.0MHz |
| 350.000 | 350.000 | yes | -0.345 | 0.085 | 2297 | 1662 | 0 | 0.251429 | timing_failed_bitstream_generated_dsp0 |
| 360.000 | 360.000 | no |  |  |  |  |  | 0.244444 | blocked_plle2_vco_range_1800.0MHz |

## 当前结论

当前最高时序通过频点为 300.000 MHz，`cnt_test=88`，理论执行时间约 0.293333 us。
320.000 MHz(WNS -0.250 ns)、333.333 MHz(WNS -0.143 ns)、350.000 MHz(WNS -0.345 ns) 均已生成 bitstream，但 setup 时序不收敛，不能进入有效速度榜。

340 MHz 和 360 MHz 若被标记为 `blocked_plle2_vco_range`，表示对应整数 PLL 配置下 VCO 超出 7 Series PLLE2 常用合法范围，不能作为有效实现成绩。
