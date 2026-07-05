# V60_component_owner_300

V60 是在 V59 之后继续迭代得到的 16 核 component-owner 路线。它把 8 点复数 FFT 的 16 个输出分量拆给 16 个完整 MCU core：每个 core 负责一个 verify 地址，并通过普通 32-bit ARM-like 指令完成读取、乘加和写回。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 来源路线 | `V59_octa_fast_stop_300` |
| 核数 | 16 个完整 MCU core |
| 目标器件 | `xc7k160tffg676-2` |
| 目标频率 | 300 MHz |
| 正式计分 `cnt_test` | 38 |
| 300 MHz 理论时间 | 0.127 us |
| FFT 速度 | 789.47 万次/秒 |
| 官方样例 + 20 组随机 | PASS |
| no-ILA WNS/TNS | +0.014 ns / 0.000 ns |
| no-ILA WHS/THS | +0.064 ns / 0.000 ns |
| no-ILA LUT/FF/DSP/BRAM | 16970 / 13203 / 0 / 0 |
| no-ILA DRC | 0 checks found |
| no-ILA bitstream | 已生成并已下载上板 |
| ILA 证明版 | 300 MHz timing clean，并已抓取 fast-stop 证据 |
| 上板状态 | PASS |

V60 当前是仓库中最快的已上板路线。V59 的 `cnt_test=49`，V60 降到 `cnt_test=38`，在 300 MHz 下约快 `1.29x`。

## 设计要点

- 每个 core 都保留完整 MCU 结构，包括 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 每个 core 执行独立的 32-bit ARM-like 普通指令 ROM。
- 每个 core 只负责一个 verify 地址，因此不需要 shared RAM 合并 partial sum。
- verify 写回仍由普通 `STR` 指令触发，16 个地址均由各自 owner core 写入。
- 输入读取通过普通 `LDR` 访问测试 ROM，计算使用普通 `ADD/SUB/MUL`。
- `MUL` 是 MCU ISA 中已有的普通 Q7 乘法指令，不是 FFT、复数或蝶形专用指令。
- Vivado 使用 `max_dsp=0` 约束，最终 DSP 使用量为 0。

## 上板证明摘要

V60 已完成两类上板：

1. 无 ILA 最终版下载：`program_status=ok`，下载后 `ilas_after_no_ila_program=0`。
2. ILA 证明版下载并抓取：触发 `fast_stop_pulse_dbg`，导出 `board_validation/v60_ila_fast_stop_capture.csv`。

ILA 比对结果：

| 检查项 | 结果 |
| --- | --- |
| verify 写回次数 | 16 |
| 唯一 verify 地址数 | 16 |
| 最后写回地址 | 15 |
| 最后写回采样点 / `cnt_test` | sample 31 / 36 |
| `fast_stop_pulse_dbg` 采样点 / `cnt_test` | sample 32 / 37 |
| `done` 稳定采样点 / `cnt_test` | sample 33 / 38 |
| `verify_done_mask_q` at fast-stop | `0xffff` |
| `verify_done_mask_next` at fast-stop | `0xffff` |
| 输出值比对 | PASS |
| 是否提前停表 | PASS，未提前停表 |

说明：正式计分沿用回归和稳定 `done` 后读到的 `cnt_test=38`。ILA 在 `fast_stop_pulse_dbg` 当拍看到 `cnt_test=37`，下一拍 `done=1` 后计数稳定为 `38`，与仿真回归一致。这里的关键证据是：最后一批 verify 写回已经在 fast-stop 前一拍完成，fast-stop 当拍 `verify_done_mask_q/next` 均为 `0xffff`。

## 常用命令

功能回归：

```powershell
cd routes_ultra\V60_component_owner_300\mcu_fft_v60_component_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

合规审计：

```powershell
py scripts\octa_audit.py
```

基础指令仿真：

```powershell
iverilog -g2005 -I rtl -I tb -o build\tb_standard_instruction.vvp tb\tb_standard_instruction.v rtl\mcu_core.v rtl\instr_rom.v rtl\data_ram.v rtl\ext_test_rom_if.v rtl\verify_ram_if.v rtl\decoder.v rtl\control_unit.v rtl\reg_file.v rtl\alu.v
vvp build\tb_standard_instruction.vvp +INSTR_MEM=mem\instr_standard.mem
```

300 MHz no-ILA Vivado：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v60_no_ila.tcl -tclargs 300
```

上板下载与 ILA 证明：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v60_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v60_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v60_ila_fast_stop.tcl
py board_validation\compare_v60_ila_capture.py
```

## 关键证据

- `results/regression_summary.txt`
- `results/verify_writer_trace.csv`
- `results/input_read_trace.csv`
- `results/opcode_summary_all.csv`
- `results/forbidden_module_scan.txt`
- `results/forbidden_opcode_scan.txt`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `results/vivado_board/board_drc.rpt`
- `results/vivado_board/board_bitstream_status.txt`
- `board_validation/BOARD_VALIDATION_REPORT.md`
- `board_validation/v60_hw_compare_status.txt`
- `board_validation/v60_fast_stop_proof.csv`
