# V56 合规说明

V56 仍是八个完整 MCU core 的 output-owner 路线，不是 FFT 专用硬件加速器。

| 检查项 | 结论 |
| --- | --- |
| FFT engine | 未新增 |
| butterfly_unit / fft_stage_unit | 未新增 |
| twiddle_engine | 未新增 |
| DMA controller / coprocessor | 未新增 |
| FFT/复数/蝶形专用指令 | 未新增 |
| verify 写回 | 普通 `STR` 指令 |
| 计算指令 | 普通 `ADD/SUB/MUL` |
| DSP | 0 |
| 官方样例 + 20 随机 | PASS |

V56 的 `±91` bucket 聚合属于普通指令调度和代数化简，不改变 MCU 架构边界。
