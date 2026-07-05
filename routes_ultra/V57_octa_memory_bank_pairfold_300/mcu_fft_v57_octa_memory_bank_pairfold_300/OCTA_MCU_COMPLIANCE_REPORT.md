# V57 合规说明

V57 只改普通 MCU 指令序列，不改变硬件加速边界。

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

V57 的 pair-fold 是指令级公式整理，所有中间值仍由 MCU core 的普通寄存器和普通 ALU/MUL 路径产生。
