# V45 300 MHz 上板验证记录

验证日期：2026-07-05

## 验证对象

- 路线：`V45_stage2_wait_reduce_300`
- 工程：`routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300`
- Vivado part：`xc7k160tffg676-2`
- 硬件目标：`localhost:3121/xilinx_tcf/Digilent/210251A08870`
- 识别器件：`xc7k160t_0`
- 板载输入时钟：50 MHz
- MCU 工作时钟：`board_top.v` 中 `PLLE2_BASE` 生成 300 MHz
- no-ILA 正式 bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit`
- ILA 调试 bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_ila/mcu_fft_board.runs/impl_1/board_top.bit`

## 正式 no-ILA 指标

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 85 |
| 300 MHz 理论时间 | 0.283 us |
| WNS | +0.091 ns |
| TNS | 0.000 ns |
| WHS | +0.127 ns |
| THS | 0.000 ns |
| LUT | 2228 |
| FF | 1619 |
| DSP | 0 |
| BRAM | 0 |

no-ILA 下载状态见 `no_ila_program_status.txt`。下载后 `ilas_after_no_ila_program=0`，说明最终留在开发板上的版本不含 ILA 调试核。

## ILA 调试验证

ILA 调试版用于观察：

- `test_vector_in`
- `verify_vector_out`
- `verify_we`
- `verify_addr`
- `cnt_test`
- `done`

执行脚本：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v45_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v45_ila_verify_we.tcl
py board_validation\compare_v45_ila_capture.py
```

抓波时在脚本显示 `action=press_and_release_KEY1_reset` 后，按下并松开 `KEY1` 触发一次完整计算。

## 板上比对结果

| 项目 | 结果 |
| --- | --- |
| ILA 实例 | `hw_ila_1` |
| 触发条件 | `verify_we == 1` |
| 抓取状态 | PASS |
| verify 写回次数 | 16 |
| 覆盖地址 | 0..15 |
| 最后写回地址 | 15 |
| 最后写回时 `cnt_test` | 84 |
| `done` 稳定后 `cnt_test` | 85 |
| 输出比对 | 与 `FFT_output.coe` 完全一致 |
| 总体验证 | PASS |

详细文件：

- `capture_v45_ila_status.txt`
- `v45_ila_verify_we_capture.csv`
- `v45_hw_compare.csv`
- `v45_hw_compare_status.txt`

## ILA 版时序说明

ILA 调试版会额外引入 debug hub、ILA RAM 和探针扇出，因此只作为功能观察证据，不作为最终速度成绩。该版本实现结果为：

| 项目 | 结果 |
| --- | ---: |
| ILA 版 WNS | -0.068 ns |
| ILA 版 TNS | -0.237 ns |
| ILA 版 WHS | +0.057 ns |
| ILA 版 LUT | 3556 |
| ILA 版 FF | 3883 |
| ILA 版 DSP | 0 |
| ILA 版 BRAM | 2 |

最终成绩仍以 no-ILA timing-clean bitstream 为准。完成 ILA 抓波和比对后，已经重新下载 no-ILA bitstream。
