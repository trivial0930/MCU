# 32-bit ARM-like 合规说明

本项目使用课程 MCU 的 32-bit ARM-like 固定宽度 RISC 子集。它不是官方 ARM 二进制编码，但满足本实验中“32 位指令字、普通取指/译码/执行/访存/写回路径”的展示要求。

## 指令与机器码

- 指令字宽度：32 bit。
- 寄存器、ALU、写回语义：保留普通 MCU 数据通路口径。
- 指令来源：普通 instruction ROM。
- 支持普通数据处理、load/store、branch、HALT、NOP。
- 可通过本仓库 assembler/disasm 相关脚本反查 opcode 分布。

## 禁止项检查

| 项目 | 状态 |
| --- | --- |
| BFY / FFT_STAGE 专用 opcode | 无 |
| CMUL / CADD / CSUB 专用 opcode | 无 |
| FFT engine | 无 |
| butterfly unit | 无 |
| DMA | 无 |
| coprocessor | 无 |
| DSP | 0 |

opcode 汇总见 `results/final_opcode_summary.csv`。

## 答辩表述建议

建议表述为：本设计是课程自定义 MCU 的 32-bit ARM-like RISC 子集，保留普通 MCU 微架构路径，并使用普通指令调度完成 FFT8。它不依赖专用 FFT 指令或专用 FFT 硬件。
