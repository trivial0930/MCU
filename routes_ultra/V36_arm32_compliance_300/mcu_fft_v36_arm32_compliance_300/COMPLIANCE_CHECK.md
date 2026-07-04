# V36 合规检查说明

本文件用于回答老师提出的“机器码和架构位宽”检查点。

## 1. 指令机器码是 32 位

证据文件：

- `rtl/instr_rom.v`
- `scripts/assembler.py`
- `mem/instr_fft8.mem`

关键点：

- `instr_rom.v` 中指令存储为 `reg [31:0] rom [0:1023]`。
- `mcu_core.v` 的取指输入为 `input wire [31:0] instr`。
- `assembler.py` 输出每条指令为 8 个十六进制字符，即 32 bit。

示例：

```text
50000000
55002000
5600005b
57001000
78100080
```

## 2. 架构数据通路是 32 位

证据文件：

- `rtl/reg_file.v`
- `rtl/mcu_core.v`
- `rtl/ext_test_rom_if.v`
- `rtl/verify_ram_if.v`

关键点：

- `reg_file.v` 中 `DATA_W = 32`。
- RF 读端口、ID 操作数、EX 操作数、ALU 快速结果、前递数据、WB 写回数据均为 `signed [31:0]`。
- ADD/SUB 使用 33 位临时结果，写回 32 位，符合 32 位处理器常见实现方式。
- 乘法为普通 `MUL` 指令触发的顺序移加 Q7 乘法，不是 FFT 专用硬件；累加器扩展为 42 位以容纳 32 位操作数与 8 位系数乘积。

## 3. 存储和外设接口说明

实验测试 ROM、数据 RAM、verify 输出仍是 16 位接口，这是由 FFT 样例数据和测试平台决定的 I/O 宽度，不代表 MCU 架构位宽。

处理方式：

- LDR 读入 16 位数据后符号扩展为 32 位。
- FFT 输入样例按原定点口径左移 7 位后进入 32 位寄存器。
- STR 写 verify 时输出低 16 位，与官方 `FFT_output.coe` 比较。

## 4. 没有新增违规硬件

V36 没有新增：

- FFT engine
- butterfly unit
- fft stage unit
- twiddle engine
- DMA/AXI 加速器
- ARM 协处理器
- BFY/FFT_STAGE/BUTTERFLY/CMUL/CADD/CSUB 等专用指令

FFT 仍由指令 ROM 中的普通 `LDR/STR/ADD/SUB/MUL/MOVI/HALT` 程序完成。

## 5. 展示建议

如果老师只检查 32 位机器码和架构位宽，建议展示：

1. `mem/instr_fft8.mem`：每行 8 位十六进制机器码。
2. `rtl/instr_rom.v`：`reg [31:0] rom`。
3. `rtl/reg_file.v`：`DATA_W = 32`。
4. `rtl/mcu_core.v`：`signed [31:0]` 的 RF、EX、WB、forward 通路。
5. `results/regression_summary.txt`：官方样例 + 20 随机 PASS。
6. `results/vivado_board/board_timing_summary.rpt` 和 `board_utilization.rpt`：300 MHz timing-clean，DSP=0。

注意：V36 是 ARM-like 教学 MCU 子集，不是官方 ARMv7 二进制兼容核。如果老师要求严格执行官方 ARM 指令编码，需要在 V36 基础上继续补 ARM 官方编码译码层。
