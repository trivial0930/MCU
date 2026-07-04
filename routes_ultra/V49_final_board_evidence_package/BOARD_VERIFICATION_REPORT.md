# 上板验证报告

## 路线

最终已上板路线：V45 Stage2 Wait Reduce。

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 是否上板 | YES |
| 目标器件 | `xc7k160tffg676-2` |
| 硬件目标 | `localhost:3121/xilinx_tcf/Digilent/210251A08870` |
| 识别器件 | `xc7k160t_0` |
| 板载输入时钟 | 50 MHz |
| MCU 工作频率 | 300 MHz |
| `cnt_test` | 85 |
| 理论时间 | 0.283 us |
| no-ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit` |
| ILA 观察信号 | `done`, `verify_we`, `verify_addr`, `verify_vector_out`, `cnt_test`, `test_vector_in` |
| `verify_we` 次数 | 16 |
| 覆盖地址 | 0..15 |
| 最后写回地址 | 15 |
| `done` 稳定后 `cnt_test` | 85 |
| 输出是否匹配 `FFT_output.coe` | YES |
| DSP | 0 |

## 证据位置

- V45 原始上板材料：`routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300/board_validation/`
- V49 汇总 trace：`results/final_verify_write_trace.csv`
- V49 timing：`results/final_timing_summary.txt`
- V49 utilization：`results/final_utilization_summary.txt`
- no-ILA 下载状态：`results/v45_no_ila_program_status.txt`
- ILA 抓取状态：`results/v45_ila_capture_status.txt`
- ILA 比对状态：`results/v45_hw_compare_status.txt`

## 注意事项

ILA 调试版不是最终成绩口径。最终展示和资源统计应使用 no-ILA bitstream；ILA 版只用于证明 `verify_we`、`verify_addr`、`verify_vector_out` 和 `cnt_test` 的板上行为。
