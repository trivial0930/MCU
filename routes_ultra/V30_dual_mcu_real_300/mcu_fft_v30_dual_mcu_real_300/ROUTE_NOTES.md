# V30 路线记录：真实双 MCU 并行输出拆分

## 来源

V30 从 `routes_ultra/V29_dual_mcu_300/mcu_fft_v29_dual_mcu_300` 复制而来，保留两个完整 `mcu_core` 实例，并把 Core1 从 idle 程序改成真实参与输出阶段的普通 MCU 程序。

## 任务划分

| 模块 | 任务 |
| --- | --- |
| Core0 | 读取官方 test ROM 输入，完成 Stage 1、Stage 2，并完成 Stage 3 的前两个 W0 蝶形输出 |
| Core1 | 等待 Stage 2 结果稳定后，从 shared_data_ram 读取中间值，完成 Stage 3 的后两个 W0 蝶形输出 |
| shared_data_ram | 普通共享数据 RAM，双镜像读端口，单写优先，不做 FFT 计算或重排 |
| verify 输出 | Core0/Core1 的 `verify_we` 通过普通 mux 汇总，最终地址 15 由 Core1 写入 |
| 全局计数 | `first_test_rom_read_core0 | first_test_rom_read_core1` 到 `last_verify_ram_write_core0 | last_verify_ram_write_core1`，未修改口径 |

Core1 程序不是 idle：它执行 8 条 LDR、4 条 ADD、4 条 SUB、8 条 STR，并且写入 `verify_RAM[1,3,5,7,9,11,13,15]`。最终 `verify_RAM[15]` 由 Core1 写入，因此 Core1 结果直接影响最终输出和 `cnt_test` 停止时刻。

## 修改文件

- `scripts/gen_fft8_official_asm.py`：生成 Core0/Core1 两份普通汇编程序。
- `scripts/run_official_regression.py`：同时汇编 `instr_fft8.mem` 与 `instr_core1.mem`。
- `rtl/mcu_top.v`：Core1 使用 `instr_core1.mem`，两个 core 接入共享 RAM，verify 输出汇总。
- `rtl/shared_data_ram.v`：新增普通共享 RAM。
- 删除旧的 `asm/idle_core1.asm`、`mem/instr_idle.coe`、`mem/instr_idle.mem`。

## 指令统计

| 项目 | Core0 | Core1 |
| --- | ---: | ---: |
| 总指令数 | 134 | 154 |
| LDR | 40 | 8 |
| STR | 40 | 8 |
| ADD | 22 | 4 |
| SUB | 23 | 4 |
| MUL | 4 | 0 |
| MOVI | 4 | 2 |
| NOP | 0 | 127 |
| HALT | 1 | 1 |

Core1 的 NOP 用于普通同步等待，不参与计算，不改变计数口径。当前版本没有引入专用同步硬件；同步依赖固定指令调度。

## 验证结果

| 项目 | 结果 |
| --- | ---: |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 149 |
| 300 MHz timing | PASS |
| 理论时间 | 0.497 us |
| WNS/TNS | +0.021 ns / 0.000 ns |
| WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF/DSP | 2076 / 1318 / 0 |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v30_dual_mcu_real_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## 结论

V30 是当前最快的 Ultra 300 MHz 路线，且 Core1 真实参与输出阶段。它符合“不新增 FFT engine、butterfly_unit、DMA、协处理器或专用指令”的要求，但 WNS 余量只有 +0.021 ns，明显低于 V31。建议作为双核高性能候选保留；若要上板展示，建议先生成带 ILA 版本确认 Core1 写回的地址和值。
