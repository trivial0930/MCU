# V30_dual_mcu_real_300

V30 是从 V29 推进而来的真实双 MCU 路线。Core0 负责输入、Stage 1/2 和前半输出；Core1 通过普通 MCU 指令读取共享 RAM，完成后半 Stage 3 输出。

| 项目 | 结果 |
| --- | ---: |
| 架构 | 双完整 MCU |
| `cnt_test` | 149 |
| MCU 频率 | 300 MHz |
| 理论时间 | 0.497 us |
| WNS/TNS | +0.021 ns / 0.000 ns |
| WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF/DSP | 2076 / 1318 / 0 |
| 回归 | 官方样例 + 20 随机 PASS |

V30 是当前最快路线，但时序余量较薄；上板前建议先做 ILA 验证。详细记录见 `mcu_fft_v30_dual_mcu_real_300/ROUTE_NOTES.md`。
