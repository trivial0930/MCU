# routes_ultra：V10/V11/V12 高频实验路线

本目录保存基于 `MCU_FFT_300MHz_extreme_optimization_report.pdf` 落地的三条高频实验路线。三条路线都从已经上板验证过的 Route A `speed_v7_q7_narrow_mul` 派生，保持以下统一口径：

- 目标器件：`xc7k160tffg676-2`
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/时序统计：关闭 ILA
- 输入板载时钟：50 MHz，通过 `PLLE2_BASE` 产生路线目标时钟

## 目录结构

| 路线 | 工程目录 | 主要改动 | 目标时钟 |
| --- | --- | --- | ---: |
| V10 | `V10_width_reduce/mcu_fft_v10_width_reduce` | 25 bit 寄存器堆和 ALU 窄化，读出时符号扩展到 32 bit | 150 MHz |
| V11 | `V11_2stage_core/mcu_fft_v11_2stage_core` | 在 V10 基础上增加 `instr_id` 取指寄存器边界 | 200 MHz |
| V12 | `V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300` | 在 V10 基础上将 `MUL` 改为启动/写回两周期控制 | 300 MHz |

## 当前结论

三条路线已经完成 RTL 开发、本地回归、Vivado 综合、实现、DRC 和 bitstream 生成；开发板 JTAG 链路也已经识别到 `xc7k160t_0`。但是三条高频目标均未满足 post-route setup timing，因此当前 bitstream 只能作为极限实验产物，不能作为“高频上板通过”的最终成绩。

| 路线 | 回归 | `cnt_test` | 目标频率 | 理论时间 | WNS | LUT | FF | DSP | DRC |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| V10 | 官方样例 + 20 组随机 PASS | 157 | 150 MHz | 1.047 us | -0.664 ns | 904 | 448 | 0 | 0 Error，CFGBVS warning |
| V11 | 官方样例 + 20 组随机 PASS | 157 | 200 MHz | 0.785 us | -1.319 ns | 902 | 481 | 0 | 0 Error，CFGBVS warning |
| V12 | 官方样例 + 20 组随机 PASS | 161 | 300 MHz | 0.537 us | -4.099 ns | 1139 | 484 | 0 | 0 Error，CFGBVS warning |

## 常用命令

本地回归示例：

```powershell
cd routes_ultra\V10_width_reduce\mcu_fft_v10_width_reduce
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

无 ILA Vivado 实现示例：

```powershell
cd routes_ultra\V10_width_reduce\mcu_fft_v10_width_reduce
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

硬件链路检测：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source routes_ultra\vivado\detect_hw.tcl
```

## 本机 bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v10_width_reduce/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v11_2stage_core/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v12_alu_pipe_300/mcu_fft_board.runs/impl_1/board_top.bit
```

由于这些目标频率下 WNS 为负，下载前请优先参考 `路线Ultra开发上板记录.md` 中的降频建议。
