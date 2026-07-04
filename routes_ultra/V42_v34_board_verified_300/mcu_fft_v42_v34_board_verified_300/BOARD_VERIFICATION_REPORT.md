# V42 Board Verification Report

## 基本信息

| 项目 | 内容 |
| --- | --- |
| 路线名称 | `V42_v34_board_verified_300` |
| 来源路线 | `V34_dual_mcu_schedule_300` |
| 是否上板 | YES |
| 工作频率 | 300 MHz |
| `cnt_test` | 88 |
| 理论时间 | 0.293 us |
| DSP | 0 |
| no-ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## ILA 观察信号

V34/V42 上板验证使用 ILA 观察：

- `done`
- `cnt_test`
- `verify_we`
- `verify_addr`
- `verify_vector_out`
- `test_vector_in`

ILA 触发条件为 `verify_we == 1`。

## 板上验证结论

| 检查项 | 结论 |
| --- | --- |
| `done` 是否拉高 | YES |
| `verify_we` 是否 16 次 | YES |
| `verify_addr` 最后是否为 15 | YES |
| addr15 是否为最后一次可信 verify 写 | YES |
| `verify_vector_out` 是否与 `FFT_output.coe` 一致 | YES |
| `done=1` 后最终 `cnt_test` | 88 |
| addr15 写入当拍 `cnt_test` | 87 |

## 证据文件

| 文件 | 说明 |
| --- | --- |
| `board_validation/BOARD_VALIDATION.md` | V34 原始上板验证记录 |
| `board_validation/v34_ila_verify_we_capture.csv` | ILA 抓波导出的 verify 写回记录 |
| `board_validation/v34_hw_compare.csv` | ILA 捕获值与期望输出逐项比对 |
| `board_validation/v34_hw_compare_status.txt` | 逐项比对状态 |
| `board_validation/no_ila_program_status.txt` | 验证后重新下载 no-ILA bitstream 记录 |
| `results/verify_write_trace.csv` | V42 整理后的按写入顺序 verify trace |

## 资源和时序

正式资源与速度统计使用 no-ILA 版本：

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.056 ns |
| TNS | 0.000 ns |
| WHS | +0.085 ns |
| THS | 0.000 ns |
| LUT | 2228 |
| FF | 1615 |
| DSP | 0 |
| BRAM | 0 |

带 ILA 版本只用于抓波，不作为正式资源统计。

## 结论

V42 固化了 V34 的上板结果。它是当前最快已完成实物验证的 Ultra 路线，可作为后续 V43/V44/V45/V46 等实验路线的回退基线。
