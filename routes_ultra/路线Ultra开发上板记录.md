# 路线 Ultra 开发与上板记录

日期：2026-07-04

## 1. 当前目标

当前目标已经从“尝试高频路线”升级为“真正达成 300 MHz MCU 工作时钟”。因此后续判断不再只看 bitstream 是否生成，而是必须同时满足：

1. 官方 FFT 样例通过。
2. 20 组随机输入回归通过。
3. Vivado post-route setup timing clean。
4. DRC 0 Error。
5. 关闭 ILA 后统计资源和速度。

## 2. 已完成路线

| 路线 | 状态 | 说明 |
| --- | --- | --- |
| V10_width_reduce | 已完成，未过时序 | 150 MHz WNS 为负，说明只做位宽收窄不够 |
| V11_2stage_core | 已完成，未过时序 | 只切开取指边界，主执行路径仍过长 |
| V12_alu_pipe_300 | 已完成，未过时序 | 早期 MUL 多周期不足以解决整体关键路径 |
| V13_addr_decode_slim | 已完成，过 150 MHz | 窄地址译码 + IF/ID + 25 bit 数据通路，是后续 300 MHz 的稳定基础 |
| V19_pipeline_300 | 已完成，过 300 MHz | 真正流水化版本，MUL 改为顺序移加，300 MHz 余量较稳 |
| V20_forward_300 | 已完成，过 300 MHz | 在 V19 基础上增加 EX 前递，当前速度最快，但时序余量很薄 |

## 3. 关键技术变化

V19/V20 与 V10-V13 的本质区别不是 PLL 参数，而是执行路径被拆开：

- 增加发射、执行、写回流水边界。
- 将 `reg_file -> ALU/MUL/地址译码 -> writeback` 的单周期长路径拆成较短路径。
- 使用 RAW 冒险检测，必要时插入 bubble。
- 使用 WB 前递保证相邻依赖正确。
- V20 对 ADD/SUB/AND/OR/MOVI/MOVR/BL 等快速结果增加 EX 前递，减少停顿。
- `MUL` 不再走单周期 LUT 乘法，改为顺序移加，牺牲少量周期换取 300 MHz 时序。
- 继续保持 `max_dsp=0`，没有使用 DSP。

## 4. 最新 Vivado 结果

| 路线 | MCU 频率 | `cnt_test` | 理论时间 | WNS | TNS | LUT | FF | DSP | BRAM | 结论 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| V13_addr_decode_slim | 150 MHz | 157 | 1.047 us | +0.198 ns | 0.000 ns | 874 | 462 | 0 | 0 | 150 MHz 稳定基线 |
| V19_pipeline_300 | 300 MHz | 204 | 0.680 us | +0.121 ns | 0.000 ns | 860 | 675 | 0 | 0 | 推荐的 300 MHz 稳健版 |
| V20_forward_300 | 300 MHz | 197 | 0.657 us | +0.004 ns | 0.000 ns | 989 | 675 | 0 | 0 | 当前最快版，余量极薄 |

V20 的最差路径：

- Source：`u_mcu_top/u_mcu_core/ex_op1_reg[3]/C`
- Destination：`u_mcu_top/u_mcu_core/wb_wdata_reg[7]/D`
- Requirement：3.333 ns
- Data Path Delay：3.334 ns
- Logic Levels：11

说明：Vivado 仍报告 WNS 为 `+0.004 ns`，因此 post-route timing 是通过的，但已经非常贴边。上板时如果出现温度、电压或板级不稳定，优先回退到 V19。

## 5. 当前推荐上板顺序

1. 先下载 V19 无 ILA bitstream，确认 300 MHz 功能稳定。
2. 再下载 V20 无 ILA bitstream，确认当前最快版本是否稳定。
3. 如需抓波，单独生成 ILA 版本；不要用 ILA 版本做最终资源和速度成绩。
4. 抓波重点观察：
   - `done`
   - `verify_we`
   - `verify_addr`
   - `verify_vector_out`
   - `cnt_test`
5. 若 V20 上板不稳定，保留 V20 作为极限实验结果，实际展示采用 V19。

## 6. 命令

V20 本地回归：

```powershell
cd routes_ultra\V20_forward_300\mcu_fft_v20_forward_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V20 无 ILA 综合实现和 bitstream：

```powershell
cd routes_ultra\V20_forward_300\mcu_fft_v20_forward_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

V19 无 ILA bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300/mcu_fft_board.runs/impl_1/board_top.bit
```

V20 无 ILA bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v20_forward_300/mcu_fft_board.runs/impl_1/board_top.bit
```

## 7. 后续更激进方向

下一步不要继续靠提高 PLL 硬冲。V20 的 WNS 只有 `+0.004 ns`，继续加频风险很高。更有效的方向是：

1. 优化顺序 MUL：把 8 次移加改成 4 次 radix-4 移加，目标把 `cnt_test` 从 197 继续压到 181 左右。
2. 将 EX 前递路径再切一拍，避免 V20 当前 11 级逻辑成为新的瓶颈。
3. 对 FFT 程序做指令调度，把独立 LDR/STR/ADD 穿插到 MUL 等待期间，减少流水停顿。
4. 如老师允许，可研究半精度或块浮点数据格式；但不建议加入专用 FFT 协处理器或 DMA 旁路，否则容易偏离“MCU 指令驱动”的要求。
