# V60_component_owner_300

V60 是在 V59 之后继续迭代得到的 16 核 component-owner 路线。它把 8 点复数 FFT 的 16 个输出分量拆成 16 个完整 MCU core：Core0 到 Core7 分别负责 `real(X0)` 到 `real(X7)`，Core8 到 Core15 分别负责 `imag(X0)` 到 `imag(X7)`。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 来源路线 | `V59_octa_fast_stop_300` |
| 核数 | 16 个完整 MCU core |
| 目标器件 | `xc7k160tffg676-2` |
| 目标频率 | 300 MHz |
| `cnt_test` | 38 |
| 300 MHz 理论时间 | 0.127 us |
| 官方样例 + 20 组随机 | PASS |
| no-ILA WNS/TNS | +0.014 ns / 0.000 ns |
| no-ILA WHS/THS | +0.064 ns / 0.000 ns |
| no-ILA LUT/FF/DSP/BRAM | 16970 / 13203 / 0 / 0 |
| DRC | 0 checks found |
| bitstream | 已生成 |
| 上板状态 | 尚未上板 |

V60 目前是仓库中最快的已实现 bitstream 路线；V59 仍然是最快的已上板且完成 ILA fast-stop 证明的路线。

## 设计要点

- 每个 core 都保留完整 MCU 结构，包括 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 每个 core 执行独立的 32-bit ARM-like 普通指令 ROM。
- 每个 core 只负责一个 verify 地址，因此不需要 shared RAM 合并 partial sum。
- verify 写回仍由普通 `STR` 指令触发，16 个地址均由各自 owner core 写入。
- 输入读取通过普通 `LDR` 访问测试 ROM；计算使用普通 `ADD/SUB/MUL`。
- `MUL` 仍是 MCU ISA 中已有的普通 Q7 乘法指令，不是 FFT、复数或蝶形专用指令。
- DSP 使用量被 Vivado `max_dsp=0` 约束为 0。

## 速度说明

V59 的 `cnt_test=49`，V60 降到 `cnt_test=38`。在 300 MHz 下：

- V59 理论时间约 `49 / 300 = 0.163 us`
- V60 理论时间约 `38 / 300 = 0.127 us`
- V60 相比 V59 约快 `1.29x`

V60 仍采用全系统 wall-clock 计数口径。`cnt_test` 从首个有效 FFT 输入读取开始，到 16 个 verify 地址全部可信写入后一拍停止。仿真 trace 中最后一批 verify 写发生在同一周期，`results/verify_writer_trace.csv` 已标记 `is_last_write=1`。

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

bitstream 输出位置：

```text
D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
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
