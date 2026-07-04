# V41：32-bit MCU 合规审计

## 目的

老师强调需要按照课上 32 位 ARM 指令微架构思路展示。V41 不新增一条性能路线，而是把当前 V34/V38 的合规点整理成审计材料，避免把快速成绩误解为专用加速器或非 MCU 数据通路。

## 审计结论

| 检查项 | 当前状态 |
| --- | --- |
| 32-bit 指令字 | `instr_rom` 输出 32-bit 指令 |
| 32-bit 寄存器堆接口 | `reg_file` 读写数据为 32-bit |
| 32-bit ALU/WB 外部语义 | `mcu_core` 使用 32-bit operand、ALU、writeback |
| FFT 数据格式 | 存储和 verify 输出使用 16-bit 定点数据 |
| Core1 是否真实参与 | V33/V34/V38 中 Core1 执行 Stage2 和 Stage3 普通指令 |
| 是否使用 DSP | Vivado `max_dsp=0`，报告 DSP=0 |
| 是否有专用 FFT 指令 | 无 |
| 是否有 FFT engine/DMA/coproc | 无 |

## 可展示代码位置

- `rtl/instr_rom.v`：32-bit 指令输出。
- `rtl/reg_file.v`：32-bit 寄存器堆读写接口。
- `rtl/mcu_core.v`：32-bit operand、ALU、WB 数据路径。
- `scripts/gen_fft8_official_asm.py`：Core0/Core1 普通指令生成逻辑。
- `asm/fft8_core1_output.asm`：Core1 的实际普通指令流。

## 对 V34/V38 的说明

V34 和 V38 的速度提升来自：

1. 双 MCU 并行调度。
2. Core1 分担 Stage2 `(5,7,W2)`。
3. Core1 分担后半 Stage3 输出。
4. V38 进一步调整等待和最后 addr15 写回时序。

这些变化都体现在普通指令流中，不是新增硬件蝶形单元。V38 的 `CORE1_FINAL_ADDR15_DELAY_NOP=9` 只是为了让最后一次 `STR` 对齐全局最后输出，保证 `cnt_test` 停表可信。

## 展示建议

- 如果老师重点查“32 位机器码”：展示 `instr_rom.v` 和汇编器输出 `.coe/.mem`。
- 如果老师重点查“架构位宽”：展示 `reg_file.v`、`alu.v`、`mcu_core.v` 的 32-bit 信号。
- 如果老师重点查“是否专用加速”：展示没有专用 opcode、没有 FFT engine、没有 DSP，并展示 Core1 汇编中的 `LDR/ADD/SUB/MUL/STR`。
