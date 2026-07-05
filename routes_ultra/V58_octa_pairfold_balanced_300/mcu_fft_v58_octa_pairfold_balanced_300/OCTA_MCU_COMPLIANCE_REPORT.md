# V58 合规说明

V58 仍然是八个完整 MCU core 的普通指令路线。

| 检查项 | 结论 |
| --- | --- |
| FFT engine | 未新增 |
| butterfly_unit / fft_stage_unit | 未新增 |
| twiddle_engine | 未新增 |
| DMA controller / coprocessor | 未新增 |
| FFT/复数/蝶形专用指令 | 未新增 |
| verify 写回 | 普通 `STR` 指令 |
| 计算指令 | 普通 `LDR/ADD/SUB/MUL/STR` |
| DSP | 0 |
| 官方样例 + 20 随机 | PASS |

V58 的速度收益来自普通指令调度和符号化简，不依赖测试数据硬编码。20 组随机输入已全部通过。
