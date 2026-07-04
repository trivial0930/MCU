# V42 Compliance Report

## 结论

V42 是 V34 的已上板验证固化版，保持两个完整 MCU、普通 32-bit ARM-like 指令字、普通取指/译码/执行/访存/写回路径。它没有引入 FFT 专用硬件，也没有引入 FFT/复数/蝶形专用指令。

## 双 MCU 结构

Core0 和 Core1 都是完整 MCU。每个 core 都包含：

- PC / `instr_addr`
- `instr_rom`
- `decoder`
- `control_unit`
- `reg_file`
- `alu`
- load/store 数据通路
- writeback 数据通路
- `verify_ram_if`
- `ext_test_rom_if`

Core1 不是协处理器，不是 FFT engine。Core1 与 Core0 一样从独立普通指令 ROM 取指，执行 `LDR/ADD/SUB/MUL/STR/NOP/HALT` 等普通指令。

## 存储与输出

- shared RAM 只做普通数据存储，不参与 FFT 计算。
- verify RAM 必须由普通 `STR` 指令写入。
- `cnt_test` 是全系统 wall-clock 计数，从第一次有效输入读取到最后一次可信 verify 输出写入完成。
- V42 没有修改 `cnt_test` 口径。

## 禁止项检查

| 禁止项 | V42 状态 |
| --- | --- |
| FFT engine | 无 |
| butterfly_unit | 无 |
| fft_stage_unit | 无 |
| twiddle_engine | 无 |
| DMA controller | 无 |
| coprocessor | 无 |
| BFY / FFT_STAGE / BUTTERFLY 指令 | 无 |
| CMUL / CADD / CSUB 指令 | 无 |
| 固定三级蝶形硬件网络 | 无 |
| 自动 bit reversal 硬件 | 无 |
| 自动 real/imag merge 硬件 | 无 |
| DSP | 0 |

## 32-bit ARM-like 机器码说明

本工程使用课程 MCU 的 ARM-like 固定 32 位 RISC 子集，而不是 ARM 官方二进制编码。机器码格式由 `scripts/assembler.py` 定义：

```text
[31:28] opcode
[27:24] rd
[23:20] rs1
[19:16] rs2
[15:0]  imm16
```

该格式保持 32-bit instruction word，支持数据处理、load/store、branch、HALT/NOP 等普通 MCU 指令。若老师严格要求 ARM 官方编码而不是课程自定义 ARM-like 编码，应使用 V36/V48 作为合规展示备选。

## 证据文件

| 文件 | 说明 |
| --- | --- |
| `results/core0_disasm.txt` | Core0 机器码和普通指令反汇编 |
| `results/core1_disasm.txt` | Core1 机器码和普通指令反汇编 |
| `results/opcode_summary.csv` | Core0/Core1 opcode 统计 |
| `asm/fft8_official_sample.asm` | Core0 普通指令源程序 |
| `asm/fft8_core1_output.asm` | Core1 普通指令源程序 |

## 结论

V42 的性能来自双完整 MCU 的普通指令调度和并行写回，不是专用 FFT 硬件。它可作为当前最快已上板路线和答辩主线。
