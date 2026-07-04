# 上板验证报告

## 路线

最终已上板路线：V42/V34。

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 是否上板 | YES |
| 目标器件 | `xc7k160tffg676-2` |
| 工作频率 | 300 MHz |
| `cnt_test` | 88 |
| 理论时间 | 0.293 us |
| no-ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v42_v34_board_verified_300/mcu_fft_board.runs/impl_1/board_top.bit` |
| ILA 观察信号 | `done`, `verify_we`, `verify_addr`, `verify_vector_out`, `cnt_test`, `test_vector_in` |
| `done` | 已拉高 |
| `verify_we` 次数 | 16 |
| 最后写回地址 | 15 |
| addr15 是否最后可信写回 | YES |
| 输出是否匹配 `FFT_output.coe` | YES |
| DSP | 0 |

## 证据位置

- V42 原始上板材料：`routes_ultra/V42_v34_board_verified_300/mcu_fft_v42_v34_board_verified_300/board_validation/`
- V49 汇总 trace：`results/final_verify_write_trace.csv`
- V49 timing：`results/final_timing_summary.txt`
- V49 utilization：`results/final_utilization_summary.txt`
