# V36_arm32_compliance_300

V36 是为了回应老师“需要按书上 32 位 ARM 指令微架构，并在验收时检查机器码和架构位宽”的要求而补充的合规展示路线。它基于 V31 单核路线复制，不追求超过 V30 的速度，而是优先保证固定 32 位指令字、32 位寄存器堆、32 位 ALU/前递/写回数据通路。

| 项目 | 结果 |
| --- | ---: |
| 来源路线 | `V31_single_core_final_tune_300` |
| 架构 | 单核 32-bit ARM-like MCU |
| 指令字宽度 | 32 bit |
| 通用寄存器 | 16 个 32-bit 寄存器，`R0` 到 `R15` |
| ALU/操作数/写回 | 32 bit |
| `cnt_test` | 169 |
| MCU 频率 | 300 MHz |
| 理论时间 | 0.563 us |
| WNS/TNS | +0.157 ns / 0.000 ns |
| WHS/THS | +0.066 ns / 0.000 ns |
| LUT/FF/DSP | 1213 / 822 / 0 |
| 回归 | 官方样例 + 20 随机 PASS |

说明：

- 本路线保留普通 MCU 取指、译码、执行、写回结构，不引入 FFT engine、butterfly unit、DMA、协处理器或 FFT/复数专用指令。
- 指令 ROM 仍为 32 位机器码，`mem/instr_fft8.mem` 中每行 8 个十六进制字符。
- 数据通路从 V31 的 25 位优化版本恢复为 32 位，用于课堂合规展示。
- 该路线用于“合规兜底/展示”，速度主线仍是 `V30_dual_mcu_real_300`，最快单核速度路线仍是 `V31_single_core_final_tune_300`。

详细记录见：

- `mcu_fft_v36_arm32_compliance_300/ROUTE_NOTES.md`
- `mcu_fft_v36_arm32_compliance_300/COMPLIANCE_CHECK.md`
