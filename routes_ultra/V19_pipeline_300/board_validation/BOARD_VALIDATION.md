# V19 上板验证记录

记录时间：2026-07-04

## 验证目标

确认 V19 在实物开发板上能够完成 300 MHz MCU FFT 运算，并且输出结果与仿真期望一致。

## 硬件识别

Vivado Hardware Manager 已识别到开发板：

| 项目 | 结果 |
| --- | --- |
| JTAG 设备 | `xc7k160t_0` |
| 器件 | `xc7k160t` |
| 下载线 | Digilent `210251A08870` |

## 下载文件

本次后续验证下载的是带 ILA 的调试版本：

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300_ila/mcu_fft_board.runs/impl_1/board_top.ltx
```

下载结果：

| 项目 | 结果 |
| --- | --- |
| `program_hw_devices` | 成功 |
| startup status | `HIGH` |
| ILA core | 1 个 |

## ILA 调试版实现结果

| 项目 | 结果 |
| --- | ---: |
| MCU 频率 | 300 MHz |
| WNS | +0.088 ns |
| TNS | 0.000 ns |
| LUT | 2175 |
| FF | 2924 |
| BRAM Tile | 2 |
| DSP | 0 |

说明：ILA 调试版会额外消耗 LUT、FF 和 BRAM，因此资源数据不能直接作为最终性能版资源占用。最终交付和速度统计仍应优先使用无 ILA 版本。

## 完成态采样

采样文件：

```text
v19_ila_done_capture.csv
```

关键结果：

| 信号 | 结果 |
| --- | --- |
| `done` | `1` |
| `cnt_test` | `0x000cc` |
| 十进制周期数 | 204 |
| 按 300 MHz 推算耗时 | 0.680 us |

该结果与 V19 仿真回归中的 `cnt_test=204` 一致。

注意：本次上板直接验证的是板上周期数和输出结果；`0.680 us` 是根据 PLL 目标频率 300 MHz 推算得到的执行时间。尚未使用示波器、逻辑分析仪或独立参考计数器直接测量 start-to-done 的绝对时间。

## 写回过程采样

采样文件：

```text
v19_ila_verify_we_capture.csv
```

比对文件：

```text
v19_hw_compare.csv
```

硬件抓到 16 次 `verify_we=1`，按地址排序后与 `results/verify_output.txt` 完全一致：

| 地址 | 硬件值 | 期望值 | 结果 |
| ---: | --- | --- | --- |
| 0 | `f280` | `f280` | PASS |
| 1 | `e80a` | `e80a` | PASS |
| 2 | `1a80` | `1a80` | PASS |
| 3 | `fea2` | `fea2` | PASS |
| 4 | `e080` | `e080` | PASS |
| 5 | `16f6` | `16f6` | PASS |
| 6 | `e680` | `e680` | PASS |
| 7 | `fa5e` | `fa5e` | PASS |
| 8 | `e900` | `e900` | PASS |
| 9 | `317c` | `317c` | PASS |
| 10 | `2c00` | `2c00` | PASS |
| 11 | `1f8c` | `1f8c` | PASS |
| 12 | `0b00` | `0b00` | PASS |
| 13 | `0c84` | `0c84` | PASS |
| 14 | `1600` | `1600` | PASS |
| 15 | `d874` | `d874` | PASS |

## 结论

V19 已完成实物开发板验证：

- 300 MHz ILA 调试版可综合、实现、生成 bitstream 并成功下载。
- 板上实际运行完成，`done=1`。
- 板上实际周期数为 204，与仿真一致。
- 16 个 FFT 输出值与期望结果完全一致。
- 当前未进行外部仪器绝对时间直测；时间数据采用 `204 / 300 MHz = 0.680 us` 推算。

因此 V19 可以作为当前 300 MHz 稳定上板路线。后续若只做速度和资源统计，应切回无 ILA 版本；若继续调试 V20 或更激进路线，可以沿用本次 ILA 验证方法。
