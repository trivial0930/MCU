# V36 路线记录：32 位 ARM-like 合规展示路线

## 目标

老师新提醒中强调验收时会检查“机器码”和“架构位宽”。此前 V31/V30 虽然使用 32 位指令字，但核心数据通路为了速度和资源做过 25 位窄化。V36 的目标是补一条更适合课堂展示和合规说明的路线：

- 固定 32 位指令字。
- 16 个 32 位通用寄存器。
- 32 位 ID/EX 操作数、ALU 快速路径、前递、写回。
- LDR 从 16 位数据 RAM / 测试 ROM 读取后符号扩展到 32 位。
- STR/verify 输出仍按实验平台接口写出低 16 位。
- 不新增 FFT 专用硬件，不新增 FFT/复数/蝶形专用指令，不改 `cnt_test` 口径。

## 来源

从以下目录复制：

```text
routes_ultra/V31_single_core_final_tune_300/mcu_fft_v31_single_core_final_tune_300
```

新目录：

```text
routes_ultra/V36_arm32_compliance_300/mcu_fft_v36_arm32_compliance_300
```

选择 V31 作为来源的原因：

- 单核结构更接近课堂“一个 MCU 执行指令”的验收预期。
- V31 已经是当前最快单核路线，`cnt_test=169`。
- 不涉及双核仲裁，展示时更容易说明架构位宽和机器码。

## 修改文件

| 文件 | 修改 |
| --- | --- |
| `rtl/reg_file.v` | `DATA_W` 从 25 改为 32，通用寄存器恢复为 32 位 |
| `rtl/mcu_core.v` | RF 读数、ID 操作数、EX 操作数、ALU 结果、前递、写回全部改为 32 位 |
| `rtl/mcu_core.v` | ADD/SUB 使用 33 位临时结果后写回 32 位 |
| `rtl/mcu_core.v` | Q7 顺序乘法累加器从 34 位扩展到 42 位，适配 32 位被乘数 |
| `rtl/ext_test_rom_if.v` | 测试 ROM 输入符号扩展到 32 位，再按 FFT 定点口径左移 7 位 |
| `rtl/verify_ram_if.v` | verify 写入接口接收 32 位数据，按平台输出低 16 位 |
| `rtl/alu.v` | 保持备用 ALU 模块与 32 位数据通路一致 |

## 机器码格式

当前教学展示用固定 32 位指令字：

```text
[31:28] opcode
[27:24] rd
[23:20] rs1
[19:16] rs2
[15:0]  imm16
```

示例机器码来自 `mem/instr_fft8.mem`：

```text
50000000  ; MOVI R0, #0
55002000  ; MOVI R5, #0x2000
5600005b  ; MOVI R6, #91
57001000  ; MOVI R7, #0x1000
78100080  ; LDR R8, [R7 + 128]
```

这不是标准 ARM 官方二进制编码，而是本实验 MCU 的 ARM-like 固定 32 位 RISC 子集：包含 16 个通用寄存器、数据处理、load/store、branch、CMP/条件分支等课堂微架构要素。若老师要求严格执行 ARMv4/ARMv7 官方编码，需要再补 ARM 官方子集译码器；目前 V36 解决的是“32 位机器码 + 32 位架构位宽”的展示问题。

## 指令统计

V36 继承 V31 的汇编调度：

| 项目 | 数量 |
| --- | ---: |
| 总指令数 | 158 |
| LDR | 48 |
| STR | 48 |
| ADD | 26 |
| SUB | 27 |
| MUL | 4 |
| MOVI | 4 |
| HALT | 1 |
| first_test_rom_read | index 4：`LDR R8, [R7 + 128]` |
| last_verify_ram_write | index 156：`STR R3, [R5 + 15]` |

## 验证结果

命令：

```powershell
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

结果：

| 项目 | 结果 |
| --- | ---: |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 169 |
| 300 MHz timing | PASS |
| 理论时间 | 0.563 us |
| WNS/TNS | +0.157 ns / 0.000 ns |
| WHS/THS | +0.066 ns / 0.000 ns |
| LUT/FF/DSP | 1213 / 822 / 0 |
| DRC | 0 Error，保留 CFGBVS warning |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v36_arm32_compliance_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## 结论

V36 是推荐的“合规展示/答辩兜底”路线。它的速度与 V31 相同，资源略高，但更适合回应老师对 32 位机器码和架构位宽的检查。最终速度排名仍以 V30/V31 为主；若课堂验收重点转向 32 位架构合规性，则优先展示 V36。
