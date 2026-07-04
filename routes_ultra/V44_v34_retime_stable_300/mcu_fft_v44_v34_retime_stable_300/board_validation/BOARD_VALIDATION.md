# V34 300 MHz 上板验证记录

验证日期：2026-07-04

## 验证对象

- 路线：`V34_dual_mcu_schedule_300`
- 工程：`routes_ultra/V34_dual_mcu_schedule_300/mcu_fft_v34_dual_mcu_schedule_300`
- 板卡器件：`xc7k160t`
- Vivado part：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- MCU 工作时钟：`board_top.v` 中 `PLLE2_BASE` 生成 300 MHz
- no-ILA 正式 bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit`
- ILA 调试 bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300_ila/mcu_fft_board.runs/impl_1/board_top.bit`

## 硬件识别

Vivado Hardware Manager 已识别开发板：

```text
device=xc7k160t name=xc7k160t_0
```

## no-ILA 正式结果

正式速度和资源统计仍以 no-ILA 版本为准。

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 88 |
| 理论时间，300 MHz | 0.293 us |
| WNS | +0.056 ns |
| TNS | 0.000 ns |
| WHS | +0.085 ns |
| THS | 0.000 ns |
| LUT | 2228 |
| FF | 1615 |
| DSP | 0 |
| BRAM | 0 |

## ILA 调试版本

带 ILA 版本仅用于板上抓波验证，不作为正式资源统计口径。本次 ILA 版本同样满足 300 MHz timing。

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.023 ns |
| TNS | 0.000 ns |
| WHS | +0.048 ns |
| THS | 0.000 ns |
| LUT | 3553 |
| FF | 3868 |
| DSP | 0 |
| BRAM | 2 |

Timing report 中 `clkout_raw` 周期为 3.333 ns，频率为 300.000 MHz。

## 抓波验证

ILA 触发条件：

```text
u_ila_probe/verify_we == 1
```

抓波流程：

1. 下载 V34 ILA bitstream。
2. ILA armed 后按下并松开 `KEY1` 复位键。
3. 抓取 `verify_we`、`verify_addr`、`verify_vector_out`、`cnt_test`、`done`。
4. 使用 `compare_v34_ila_capture.py` 与 `results/expected_fft_output.txt` 做逐项比对。

抓波结论：

| 检查项 | 结果 |
| --- | --- |
| ILA 识别 | `hw_ila_1` |
| 触发状态 | PASS |
| `verify_we` 写回次数 | 16 |
| 写回地址覆盖 | 0 到 15 全覆盖 |
| 最后写回地址 | 15 |
| 最后写回当拍 `cnt_test` | 87 |
| `done=1` 后最终 `cnt_test` | 88 |
| 写回数据 | 全部匹配期望 FFT 输出 |
| 逐项比对 | PASS |

逐项比对文件：

- `v34_hw_compare.csv`
- `v34_ila_verify_we_capture.csv`
- `v34_hw_compare_status.txt`

## 板卡最终状态

ILA 验证完成后，已重新下载 no-ILA 正式 bitstream，并确认：

```text
ilas_after_no_ila_program=0
```

因此当前开发板处于 V34 no-ILA 正式版本状态。

## 结论

V34 已完成 300 MHz 实物上板验证。板上实际抓取的 16 个 FFT 输出全部与期望结果一致，最终 `cnt_test=88`，与仿真和 Vivado 结果一致。V34 可作为当前最快且已上板验证的 Ultra 路线。
