# MCU FFT Baseline

本工程是数字电路课程设计 MCU 赛题的 8 点 FFT baseline。工程使用 Verilog-2001 实现一个轻量级 MCU，并通过汇编程序完成 8 点定点复数 FFT 运算。

本工程的重点是“FFT 由 MCU 指令执行完成”，不是独立 FFT 专用硬件。

## 目录结构

- `rtl/`：MCU RTL 源码，以及用于仿真的指令 ROM。
- `asm/`：FFT 汇编程序和标准指令测试程序。
- `scripts/`：汇编器、定点 FFT 参考模型、测试向量生成器、输出检查器和 COE 转换脚本。
- `mem/`：已生成的指令和测试向量 `.mem/.coe` 文件。
- `tb/`：Verilog 仿真 testbench。
- `results/`：参考输出和仿真输出文件。

## 顶层接口

顶层模块为 `rtl/mcu_top.v`。

```verilog
module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [4:0] test_rom_addr,
    input  wire [15:0] test_vector_in,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [19:0] cnt_test,
    output wire done
);
```

外部接口说明：

- `test_rom_addr`：外部 `test_ROM` 地址。
- `test_vector_in`：外部 `test_ROM` 输出数据。
- `verify_addr`：外部 `verify_RAM` 写地址。
- `verify_vector_out`：写入外部 `verify_RAM` 的数据。
- `verify_we`：外部 `verify_RAM` 写使能。
- `cnt_test`：20 bit 独立计数器。
- `done`：程序执行完成标志。

## 内存映射

- `0x0000` 到 `0x00FF`：MCU 内部 data RAM。
- `0x1000` 到 `0x100F`：外部 `test_ROM`，对应输入信号 `test_vector_in`。
- `0x2000` 到 `0x200F`：外部 `verify_RAM`，对应输出信号 `verify_vector_out`。

`cnt_test` 在 MCU 第一次读取 `test_ROM[0]` 时开始计数，在写完 `verify_RAM[15]` 后停止。

## 指令集

指令宽度固定为 32 bit。

```text
[31:28] opcode
[27:24] rd
[23:20] rs1
[19:16] rs2
[15:0]  imm16
```

当前支持以下指令：

```text
NOP, ADD, SUB, AND, OR, MOVI, MOVR, LDR, STR,
B, BL, CMP, BEQ, BNE, MUL, HALT
```

其中 `MUL` 被定义为 Q15 定点乘法：

```text
Rd = (Rs1 * Rs2) >>> 15
```

这样可以在不增加移位指令的情况下完成 FFT 中的旋转因子乘法。

## FFT 数据格式

输入为 8 个复数采样点，共 16 个 signed 16-bit word：

```text
x0_real, x0_imag, x1_real, x1_imag, ..., x7_real, x7_imag
```

输出同样为 16 个 signed 16-bit word：

```text
X0_real, X0_imag, X1_real, X1_imag, ..., X7_real, X7_imag
```

FFT 汇编程序采用 8 点 radix-2 DIF FFT。DIF FFT 内部结果为 bit-reversed order，写出到 `verify_RAM` 前已按自然顺序重排。

## 生成测试向量

在工程根目录执行：

```sh
python3 scripts/gen_test_vector.py --seed 0 --out mem/test_vector.mem --coe mem/test_vector.coe
```

该命令会生成：

- `mem/test_vector.mem`
- `mem/test_vector.coe`

默认随机数范围较小，便于 baseline 验证。

## 汇编程序

生成 FFT 指令 ROM 初始化文件：

```sh
python3 scripts/assembler.py asm/fft8_baseline.asm -o mem/instr_fft8.mem --coe mem/instr_fft8.coe
```

生成标准指令测试初始化文件：

```sh
python3 scripts/assembler.py asm/standard_instruction_test.asm -o mem/instr_standard.mem --coe mem/instr_standard.coe
```

## 运行 FFT 仿真

使用 Icarus Verilog：

```sh
mkdir -p build
iverilog -g2005 -I rtl -I tb -o build/tb_mcu_fft8.vvp \
  tb/tb_mcu_fft8.v \
  rtl/mcu_top.v rtl/mcu_core.v rtl/instr_rom.v rtl/data_ram.v \
  rtl/ext_test_rom_if.v rtl/verify_ram_if.v rtl/cnt_test.v \
  rtl/decoder.v rtl/control_unit.v rtl/reg_file.v rtl/alu.v
vvp build/tb_mcu_fft8.vvp
```

仿真结束后会生成：

```text
results/verify_output.txt
```

## 检查 FFT 输出

生成 Python 参考结果：

```sh
python3 scripts/fft_fixed_ref.py --input mem/test_vector.mem --out results/expected_fft_output.txt
```

对比 MCU 仿真输出：

```sh
python3 scripts/check_fft_output.py --input mem/test_vector.mem --got results/verify_output.txt
```

期望输出：

```text
Overall: PASS
```

## 运行标准指令测试

```sh
mkdir -p build
iverilog -g2005 -I rtl -I tb -o build/tb_standard_instruction.vvp \
  tb/tb_standard_instruction.v \
  rtl/mcu_top.v rtl/mcu_core.v rtl/instr_rom.v rtl/data_ram.v \
  rtl/ext_test_rom_if.v rtl/verify_ram_if.v rtl/cnt_test.v \
  rtl/decoder.v rtl/control_unit.v rtl/reg_file.v rtl/alu.v
vvp build/tb_standard_instruction.vvp +INSTR_MEM=mem/instr_standard.mem
```

## Vivado 上板说明

使用 Vivado 工程时：

1. 以 `rtl/mcu_top.v` 作为顶层模块。
2. 将 `test_rom_addr` 连接到外部 `test_ROM` 的地址端口。
3. 将外部 `test_ROM` 的数据输出连接到 `test_vector_in`。
4. 将 `verify_addr`、`verify_vector_out`、`verify_we` 连接到外部 `verify_RAM`。
5. 将 `test_vector_in`、`verify_vector_out`、`verify_we`、`verify_addr`、`cnt_test` 加入 ILA。
6. 使用 `mem/test_vector.coe` 初始化外部 `test_ROM`。
7. 使用 `mem/instr_fft8.coe` 初始化指令 ROM，或将 `rtl/instr_rom.v` 替换为 Vivado ROM IP。

上板验收时重点观察：

- `test_vector_in`
- `verify_vector_out`
- `verify_we`
- `verify_addr`
- `cnt_test`
- `done`

## 当前 baseline 限制

- MCU 结构保持简单，重点用于功能验证。
- FFT 运算由汇编指令完成，没有实现专用 FFT IP。
- 没有实现流水线、Cache、分支预测或操作系统。
- `MUL` 为 Q15 专用乘法，牺牲了一点通用性，但能减少指令集复杂度。
- 当前版本更偏向可读、可验收的 baseline，后续可以继续优化指令数、周期数和资源占用。
