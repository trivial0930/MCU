# V61_testrom_addr_stable_300

V61 是在 `V60_component_owner_300` 基础上做的 WNS 稳定化版本。它保留 V60 的 16 核 component-owner 架构和 `cnt_test=38` 速度，只针对 V60 里最贴边的 test-ROM 地址控制路径做收敛优化，让 300 MHz no-ILA 版本的时序余量从 `+0.014 ns` 提高到 `+0.162 ns`。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 来源路线 | `V60_component_owner_300` |
| 路线定位 | V60 的 300 MHz WNS 稳定化版本 |
| 核数 | 16 个完整 MCU core |
| 目标器件 | `xc7k160tffg676-2` |
| 目标频率 | 300 MHz |
| 正式计分 `cnt_test` | 38 |
| 理论时间 | 0.127 us |
| FFT 速度 | 789.47 万次/秒 |
| 官方样例 + 20 组随机 | PASS |
| 基础指令集测试 | PASS, cycles=31 |
| no-ILA WNS/TNS | +0.162 ns / 0.000 ns |
| no-ILA WHS/THS | +0.043 ns / 0.000 ns |
| no-ILA LUT/FF/DSP/BRAM | 16712 / 13140 / 0 / 0 |
| no-ILA DRC | 0 checks found |
| no-ILA Methodology | 0 checks found |
| no-ILA bitstream | 已生成并已上板 |
| ILA 证明版 WNS/TNS | +0.008 ns / 0.000 ns |
| ILA 证明版 LUT/FF/DSP/BRAM | 18899 / 17070 / 0 / 12 |
| 上板状态 | PASS，最后已恢复 no-ILA |

V61 已经完成 no-ILA 上板、ILA fast-stop 证明和 no-ILA 恢复。V60 是上一版已上板最快路线；V61 的优势是同样 `cnt_test=38`，但 no-ILA WNS 余量更大，因此当前建议作为最快主展示版本。

## WNS 优化点

V60 的最差 setup path 是从 `ex_op1` 相关寄存器出发，经过 `is_test_rom` 判断和 `test_rom_addr` 选择，再进入组合 test-ROM 读数据并回到 `wb_wdata`。该路径中布线延迟占比很高，导致 300 MHz 下 WNS 只有 `+0.014 ns`。

V61 的 RTL 改动只在 [rtl/ext_test_rom_if.v](rtl/ext_test_rom_if.v)：

```verilog
assign test_rom_addr = test_offset;
```

V60 原来写法为：

```verilog
assign test_rom_addr = is_test_rom ? test_offset : 8'd0;
```

这个修改的含义是：test-ROM 地址端口始终接 `test_offset`，不再让 `is_test_rom` 参与 test-ROM 地址选择。真正写回到 MCU 寄存器的数据仍由 [rtl/mcu_core.v](rtl/mcu_core.v) 中的原有逻辑决定：

```verilog
wb_wdata <= ex_is_test_rom ? test_rom_read_data : internal_read_data;
```

因此非 test-ROM 的 `LDR` 仍然只会写回内部 data RAM 数据，test-ROM 返回值不会被误用。`first_read_pulse` 也仍然保留 `mem_read && is_test_rom` 门控，不会提前启动计数。这个改动不是新增硬件加速器，只是去掉一个对 test-ROM 地址不必要的组合控制输入。

## 关键时序结果

V61 300 MHz no-ILA 最差 setup path 已经从 V60 的 test-ROM 地址路径转移到普通 MCU 乘法累加路径：

| 项目 | V60 | V61 |
| --- | ---: | ---: |
| `cnt_test` | 38 | 38 |
| WNS | +0.014 ns | +0.162 ns |
| TNS | 0.000 ns | 0.000 ns |
| WHS | +0.064 ns | +0.043 ns |
| LUT | 16970 | 16712 |
| FF | 13203 | 13140 |
| DSP | 0 | 0 |

V61 最差 setup path：

| 项目 | 内容 |
| --- | --- |
| Slack | +0.162 ns |
| Source | `u_mcu_top/g_mcu_core[4].u_mcu_core/mul_multiplier_reg[0]/C` |
| Destination | `u_mcu_top/g_mcu_core[4].u_mcu_core/mul_acc_reg[37]/D` |
| 说明 | 普通 MCU `MUL` 的 LUT/carry 链路径，不再是 test-ROM 地址路径 |

## 上板证明摘要

V61 已完成两类上板：

1. no-ILA 正式版下载：`program_status=ok`，下载后 `ilas_after_no_ila_program=0`。
2. ILA 证明版下载并抓取：触发 `fast_stop_pulse_dbg`，导出 `board_validation/v61_ila_fast_stop_capture.csv`。

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

说明：正式计分沿用回归和稳定 `done` 后读到的 `cnt_test=38`。ILA 在 `fast_stop_pulse_dbg` 当拍看到 `cnt_test=37`，下一拍 `done=1` 后计数稳定为 `38`，与仿真回归一致。关键证据是最后一批 verify 写回已经在 fast-stop 前一拍完成，fast-stop 当拍 `verify_done_mask_q/next` 均为 `0xffff`。

## 合规说明

- 没有新增 FFT engine、butterfly unit、fft stage unit、twiddle engine、DMA controller 或 coprocessor。
- 没有新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等专用指令。
- 每个 core 都保留完整 MCU 结构，包括 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 每个 core 通过普通 `LDR/ADD/SUB/MUL/STR` 指令完成自己的输出分量计算。
- verify RAM 仍由普通 `STR` 指令写入。
- DSP 使用量为 0。
- `cnt_test` 仍是全系统 wall-clock 计数，没有改变计数口径。

## 复现命令

功能回归：

```powershell
cd routes_ultra\V61_testrom_addr_stable_300\mcu_fft_v61_testrom_addr_stable_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

合规扫描：

```powershell
py scripts\octa_audit.py
```

基础指令集测试：

```powershell
iverilog -g2005 -I rtl -I tb -o build\tb_standard_instruction.vvp tb\tb_standard_instruction.v rtl\mcu_core.v rtl\instr_rom.v rtl\data_ram.v rtl\ext_test_rom_if.v rtl\verify_ram_if.v rtl\decoder.v rtl\control_unit.v rtl\reg_file.v rtl\alu.v
vvp build\tb_standard_instruction.vvp +INSTR_MEM=mem\instr_standard.mem
```

300 MHz no-ILA Vivado：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v61_no_ila.tcl -tclargs 300
```

上板和 ILA 证明：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v61_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v61_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v61_ila_fast_stop.tcl
py board_validation\compare_v61_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v61_no_ila.tcl
```

## 关键证据

- `CODE_ARCHITECTURE_REPORT.md`
- `results/regression_summary.txt`
- `results/verify_writer_trace.csv`
- `results/opcode_summary_all.csv`
- `results/forbidden_module_scan.txt`
- `results/forbidden_opcode_scan.txt`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `results/vivado_board/board_drc.rpt`
- `results/vivado_board/board_methodology.rpt`
- `results/vivado_board/board_bitstream_status.txt`
- `results/wns_stability_notes.md`
- `board_validation/BOARD_VALIDATION_REPORT.md`
- `board_validation/v61_hw_compare_status.txt`
- `board_validation/v61_fast_stop_proof.csv`
- `board_validation/v61_hw_compare.csv`
- `board_validation/v61_ila_fast_stop_capture.csv`
