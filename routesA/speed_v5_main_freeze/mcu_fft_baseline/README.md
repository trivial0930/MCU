# MCU FFT Baseline

本目录是仓库中唯一保留的原始 baseline 工程副本。旧的顶层
`Baseline/` 目录已删除，避免和本路线重复；如果需要回看最初实现，
请从本目录进入。

本工程是数字电路课程设计 MCU 赛题的 8 点 FFT baseline。工程使用 Verilog-2001 实现一个轻量级 MCU，并通过汇编程序完成 8 点定点复数 FFT 运算。

本工程的重点是“FFT 由 MCU 指令执行完成”，不是独立 FFT 专用硬件。

## 目录结构

- `rtl/`：MCU RTL 源码，以及用于仿真的指令 ROM。
- `asm/`：FFT 汇编程序和标准指令测试程序。
- `scripts/`：汇编器、定点 FFT 参考模型、测试向量生成器、输出检查器和 COE 转换脚本。
- `mem/`：已生成的指令和测试向量 `.mem/.coe` 文件。
- `tb/`：Verilog 仿真 testbench。
- `results/`：参考输出和仿真输出文件。
- `constraints/`：K7EDAEVAL 上板约束文件。
- `vivado/`：Vivado 添加源码和创建 ILA IP 的辅助 Tcl 脚本。

## 顶层接口

仿真和 MCU 逻辑顶层为 `rtl/mcu_top.v`。

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

## 上板顶层

上板顶层为 `rtl/board_top.v`。

```verilog
module board_top(
    input  wire CLK_50M,
    input  wire KEY1,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,
    output wire LED6,
    output wire LED7,
    output wire LED8
);
```

板级连接：

- `CLK_50M`：K7EDAEVAL 主时钟，50 MHz。
- `KEY1`：低有效复位按钮，`board_top.v` 内部转换为高有效 `rst`。
- `LED1`：`done`。
- `LED2`：`verify_we`。
- `LED3` 到 `LED7`：`cnt_test` 的若干分频位，便于肉眼观察运行。
- `LED8`：当前 `verify_RAM` debug 数据异或值。

`board_top.v` 内部已经实例化：

- `test_ROM`：测试向量 ROM，初始化文件为 `mem/test_vector.mem`。
- `mcu_top`：MCU FFT 核心。
- `verify_RAM`：验收输出 RAM。
- `ila_probe`：ILA 接入封装。默认不启用；综合时定义 `ENABLE_ILA` 并生成 `ila_0` IP 后启用。

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

1. 以 `rtl/board_top.v` 作为上板顶层模块。
2. 添加 `rtl/*.v`、`mem/*.mem`、`mem/*.coe` 和 `constraints/top.xdc`。
3. `instr_rom.v` 默认读取 `mem/instr_fft8.mem`，这是指令 ROM 初始化处理。
4. `test_ROM` 默认读取 `mem/test_vector.mem`，也可以在 Vivado 中替换为 distributed memory ROM IP。
5. `verify_RAM` 是 16 x 16-bit 写 RAM，用于保存 FFT 输出。
6. 如需 ILA，先运行 `source vivado/create_ila_0.tcl` 生成 `ila_0`，并在综合宏中定义 `ENABLE_ILA`。
7. 可用 `source vivado/add_sources.tcl` 将工程源码、约束和初始化文件加入当前 Vivado project。

上板验收时重点观察：

- `test_vector_in`
- `verify_vector_out`
- `verify_we`
- `verify_addr`
- `cnt_test`
- `done`

推荐的 ILA probe 宽度：

- `probe0`：`test_vector_in[15:0]`
- `probe1`：`verify_vector_out[15:0]`
- `probe2`：`verify_we`
- `probe3`：`verify_addr[4:0]`
- `probe4`：`cnt_test[19:0]`
- `probe5`：`done`

## 约束文件

`constraints/top.xdc` 来自 `K7EDAEVAL_PIN定义.xlsx`：

- `CLK_50M`：`G22`
- `KEY1`：`AF5`
- `LED1` 到 `LED8`：`G9 F8 G10 E10 D9 B9 C9 A8`

如果你使用的板卡按钮电平与本工程假设不同，只需要修改 `rtl/board_top.v` 中的：

```verilog
assign rst = ~KEY1;
```

## 当前 baseline 限制

- MCU 结构保持简单，重点用于功能验证。
- FFT 运算由汇编指令完成，没有实现专用 FFT IP。
- 没有实现流水线、Cache、分支预测或操作系统。
- `MUL` 为 Q15 专用乘法，牺牲了一点通用性，但能减少指令集复杂度。
- 当前版本更偏向可读、可验收的 baseline，后续可以继续优化指令数、周期数和资源占用。
