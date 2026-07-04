# 路线 Ultra 开发与上板记录

日期：2026-07-04

## 1. 工作目标

根据 `MCU_FFT_300MHz_extreme_optimization_report.pdf`，将 V10、V11、V12 三条高频路线从 RTL 开发推进到功能回归、Vivado 综合实现、DRC、bitstream 生成和硬件链路检查。

## 2. 已完成内容

1. 新建 `routes_ultra/`，三条路线拆成独立工程，避免影响 Route A 稳定上板版本。
2. V10 完成宽度缩窄：
   - `reg_file` 使用 `DATA_W=25` 存储。
   - 读端符号扩展到 32 bit，保持外部接口不变。
   - ALU 的 ADD/SUB/MOV/MUL 采用窄位宽内部结果，再扩展输出。
3. V11 完成取指边界：
   - 增加 `instr_id` 寄存器。
   - 将 PC/ROM 输出与译码、寄存器读、ALU 路径分开。
   - 分支时插入 NOP 气泡。
4. V12 完成 MUL 多周期控制：
   - `MUL` 启动周期锁存操作数和目的寄存器。
   - 下一周期写回乘法结果并推进 PC。
   - 普通 ADD/SUB/LDR/STR/MOV/HALT 保持单周期。
5. 三条路线均完成官方样例 + 20 组随机输入回归。
6. 三条路线均完成 Vivado 综合、实现、DRC 和 bitstream 生成。
7. Vivado Hardware Manager 已识别开发板：
   - `devices=xc7k160t_0`
   - `device=xc7k160t name=xc7k160t_0`

## 3. Vivado 结果

| 路线 | PLL 输出目标 | `cnt_test` | WNS | TNS | LUT | FF | DSP | BRAM | 结论 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| V10_width_reduce | 150 MHz | 157 | -0.664 ns | -169.132 ns | 904 | 448 | 0 | 0 | bitstream 已生成，但未过 setup timing |
| V11_2stage_core | 200 MHz | 157 | -1.319 ns | -427.209 ns | 902 | 481 | 0 | 0 | bitstream 已生成，但未过 setup timing |
| V12_alu_pipe_300 | 300 MHz | 161 | -4.099 ns | -3121.943 ns | 1139 | 484 | 0 | 0 | bitstream 已生成，但离 300 MHz 仍有明显差距 |

三条路线 DRC 均为 0 Error，仅保留与原项目一致的 `CFGBVS/CONFIG_VOLTAGE` warning。

## 4. 判断

V10/V11/V12 的开发、回归、综合、实现和 bitstream 生成均已完成，但高频目标没有 timing-clean。因此当前不能把 150/200/300 MHz 版本作为正式上板通过版本。

从 WNS 反推关键路径：

| 路线 | 目标周期 | WNS | 估算关键路径 |
| --- | ---: | ---: | ---: |
| V10 | 6.667 ns | -0.664 ns | 约 7.331 ns |
| V11 | 5.000 ns | -1.319 ns | 约 6.319 ns |
| V12 | 3.333 ns | -4.099 ns | 约 7.432 ns |

说明：

- V10 降低了寄存器数量，但关键路径仍集中在地址计算、外设判断和写回组合链。
- V11 当前只切掉 PC/ROM 到译码的一段路径，尚未切开 `reg_file -> ALU -> writeback` 主路径。
- V12 的 MUL 多周期控制功能正确，但普通地址和写回路径仍然主导 timing；要冲 300 MHz 需要真正的 EX/WB 分级和地址译码寄存。

## 5. 下一步降频上板建议

不要直接把当前负 WNS 高频 bitstream 当作正式结果。建议先生成 timing-clean 降频版本：

| 路线 | 建议频率 | PLL 参数建议 | 目的 |
| --- | ---: | --- | --- |
| V10 | 130 MHz 或 135 MHz | 130 MHz：`MULT=26, DIV=10`；135 MHz：`MULT=27, DIV=10` | 验证宽度缩窄版能稳定上板 |
| V11 | 150 MHz | `MULT=18, DIV=6` | 验证取指寄存器边界是否稳定 |
| V12 | 130 MHz | `MULT=26, DIV=10` | 验证 MUL 多周期控制在板上功能正确 |

降频版 timing-clean 后，再打开 ILA 做一次功能抓波，重点观察：

- `done`
- `verify_we`
- `verify_addr`
- `verify_vector_out`
- `cnt_test`

最终提交成绩仍应使用关闭 ILA 的 bitstream。

## 6. 文件位置

Vivado 报告：

- `*/results/vivado_board/board_timing_summary.rpt`
- `*/results/vivado_board/board_utilization.rpt`
- `*/results/vivado_board/board_drc.rpt`
- `*/results/vivado_board/board_methodology.rpt`

本机 bitstream：

- `D:/vivado_work/routes_ultra/mcu_fft_v10_width_reduce/mcu_fft_board.runs/impl_1/board_top.bit`
- `D:/vivado_work/routes_ultra/mcu_fft_v11_2stage_core/mcu_fft_board.runs/impl_1/board_top.bit`
- `D:/vivado_work/routes_ultra/mcu_fft_v12_alu_pipe_300/mcu_fft_board.runs/impl_1/board_top.bit`
