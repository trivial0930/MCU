# V22b 300 MHz 上板验证记录

验证日期：2026-07-04

## 验证对象

- 路线：`V22b_fast_mul2_300`
- 工程：`routes_ultra/V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300`
- 板卡器件：`xc7k160t`
- Vivado part：`xc7k160tffg676-2`
- MCU 时钟：300 MHz，板载 50 MHz 经 `PLLE2_BASE` 生成
- 正式 bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v22b_fast_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit`
- ILA 调试 bitstream：`output/hardware_debug/v22b_300MHz_20260704/ila/board_top_v22b_300m_ila.bit`

## 无 ILA 正式结果

正式速度和资源统计仍以无 ILA 版本为准。

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 173 |
| 推算耗时 | 0.577 us |
| WNS | +0.122 ns |
| TNS | 0.000 ns |
| WHS | +0.086 ns |
| THS | 0.000 ns |
| LUT | 1053 |
| FF | 675 |
| DSP | 0 |

## ILA 调试版本

带 ILA 版本仅用于板上抓波验证，不作为正式资源统计口径。本次 ILA 版本同样满足 300 MHz timing。

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.114 ns |
| TNS | 0.000 ns |
| WHS | +0.081 ns |
| THS | 0.000 ns |
| LUT | 2365 |
| FF | 2928 |
| DSP | 0 |

## 抓波验证

使用 ILA 触发条件：

```text
u_ila_probe/verify_we == 1
```

触发后按下并松开 `KEY1` 复位，捕获 MCU 重新运行后的输出写回。

| 检查项 | 结果 |
| --- | --- |
| ILA 识别 | `hw_ila_1` |
| 触发状态 | PASS |
| `verify_we` 写回次数 | 16 |
| 写回地址 | 0 到 15 全覆盖 |
| 写回数据 | 全部匹配 `FFT_output.coe` |
| 最终 `done` | 1 |
| 最终 `cnt_test` | 173 |

逐项比对见：

- `v22b_hw_compare.csv`
- `v22b_ila_verify_we_capture.csv`

## 最终板卡状态

抓波结束后已重新下载无 ILA 正式 bitstream，并确认：

```text
ilas_after_no_ila_program=0
```

因此当前板卡处于无 ILA 正式版本状态。

## 结论

V22b 已完成 300 MHz 实物上板验证。板上捕获的 16 个 FFT 输出写回全部与官方 `FFT_output.coe` 匹配，实际 `cnt_test=173`，与本地仿真和 Vivado 结果一致。V22b 可作为当前 Ultra 路线的最快已上板版本。
