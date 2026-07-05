# MCU FFT 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU FFT 项目。项目目标是在 `xc7k160tffg676-2` 开发板上，使用普通 32-bit ARM-like MCU 指令完成 8 点定点复数 FFT，并保留可复现的仿真、综合、实现、bitstream、上板验证和中文说明材料。

## 最新状态

更新时间：2026-07-05

| 项目 | 当前结论 |
| --- | --- |
| 当前最快 no-ILA 稳定候选 | `routes_ultra/V61_testrom_addr_stable_300/mcu_fft_v61_testrom_addr_stable_300` |
| V61 性能 | `cnt_test=38`，300 MHz 理论时间约 `0.127 us`，FFT 速度约 `789.47 万次/秒` |
| V61 no-ILA Vivado | WNS/TNS = `+0.162 ns / 0.000 ns`，DSP 0，bitstream 已生成，尚未上板 |
| 当前最快已上板路线 | `routes_ultra/V60_component_owner_300/mcu_fft_v60_component_owner_300` |
| V60 上板结论 | `cnt_test=38`，no-ILA 已下载，ILA fast-stop 证明 PASS |
| 稳定八核展示路线 | `V59_octa_fast_stop_300`，`cnt_test=49`，已上板并完成 ILA 证明 |
| 低资源双核备份 | `V45_stage2_wait_reduce_300`，`cnt_test=85`，已上板 |

V61 是 V60 的 WNS 稳定化版本。它没有继续改变并行架构，也没有新增任何专用 FFT 硬件，只是去掉 test-ROM 地址端口上不必要的 `is_test_rom` 门控，使 300 MHz WNS 从 V60 的 `+0.014 ns` 提高到 `+0.162 ns`。如果马上验收，V60 仍是已经完成上板和 ILA 证明的最快版本；如果希望降低时序贴边风险，应先给 V61 补做上板和 ILA fast-stop 证明。

## 合规边界

当前主线坚持以下约束：

- 不新增 FFT engine、butterfly unit、fft stage unit、twiddle engine、DMA controller 或 coprocessor。
- 不新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等 FFT、复数或蝶形专用指令。
- 每个 core 均保留完整 MCU 结构，包括 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 输入读取、计算和 verify 写回均通过普通 `LDR/ADD/SUB/MUL/STR` 等指令完成。
- DSP 使用量为 0。
- `cnt_test` 保持全系统 wall-clock 计数，不通过少写 verify 或提前停表制造假加速。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `materials/` | 课程资料、板卡资料、官方输入输出样例和原始文档归档 |
| `docs/` | 上板、交接、报告摘要和调试说明 |
| `routesA/` | 路线 A 稳定候选、Vivado 矩阵和 130 MHz 上板资料 |
| `routesB/` | 路线 B 的 B1 到 B4 候选方案和中文说明 |
| `routes_ultra/` | 300 MHz 极限优化路线，当前最快 no-ILA 候选为 V61，最快已上板路线为 V60 |
| `RESULTS.md` | 当前速度榜、效率榜、推荐路线和风险说明 |
| `WINDOWS_CODEX_HANDOFF.md` | Windows + Vivado + Codex 环境继续调试清单 |

## V61 复现命令

功能回归：

```powershell
cd routes_ultra\V61_testrom_addr_stable_300\mcu_fft_v61_testrom_addr_stable_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

300 MHz no-ILA 实现：

```powershell
cd routes_ultra\V61_testrom_addr_stable_300\mcu_fft_v61_testrom_addr_stable_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v61_no_ila.tcl -tclargs 300
```

基础指令集测试：

```powershell
cd routes_ultra\V61_testrom_addr_stable_300\mcu_fft_v61_testrom_addr_stable_300
iverilog -g2005 -I rtl -I tb -o build\tb_standard_instruction.vvp tb\tb_standard_instruction.v rtl\mcu_core.v rtl\instr_rom.v rtl\data_ram.v rtl\ext_test_rom_if.v rtl\verify_ram_if.v rtl\decoder.v rtl\control_unit.v rtl\reg_file.v rtl\alu.v
vvp build\tb_standard_instruction.vvp +INSTR_MEM=mem\instr_standard.mem
```

## V60 已上板复现命令

```powershell
cd routes_ultra\V60_component_owner_300\mcu_fft_v60_component_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v60_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v60_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v60_ila_fast_stop.tcl
py board_validation\compare_v60_ila_capture.py
```

## 关键入口

- `RESULTS.md`
- `routes_ultra/README.md`
- `routes_ultra/results/ultra_summary.csv`
- `routes_ultra/V61_testrom_addr_stable_300/mcu_fft_v61_testrom_addr_stable_300/README.md`
- `routes_ultra/V61_testrom_addr_stable_300/mcu_fft_v61_testrom_addr_stable_300/ROUTE_NOTES.md`
- `routes_ultra/V61_testrom_addr_stable_300/mcu_fft_v61_testrom_addr_stable_300/results/wns_stability_notes.md`
- `routes_ultra/V60_component_owner_300/mcu_fft_v60_component_owner_300/board_validation/BOARD_VALIDATION_REPORT.md`

## 协作约定

- GitHub 远端使用 SSH：`git@github.com:trivial0930/MCU.git`。
- 中文文档统一使用 UTF-8 编码。
- `build/`、`.Xil/`、Vivado 工程缓存、随机临时输出和 bitstream 大文件不提交。
- 提交到 GitHub 的内容优先保留源码、脚本、关键报告、榜单 CSV/Markdown 和可复现实验命令。

