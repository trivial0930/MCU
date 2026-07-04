# 最终报告

## 最终展示路线

当前最终实物展示路线为 `V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300`。

选择原因：V45 是当前最快的合规实现路线，已经完成官方样例 + 20 组随机回归、300 MHz no-ILA timing-clean 实现、no-ILA 下载、ILA 抓波验证、结果 CSV 比对，并在验证结束后重新下载 no-ILA bitstream。它不依赖 FFT IP、DSP IP、DMA、协处理器或专用 FFT 加速器。

## 核心指标

| 项目 | 结果 |
| --- | --- |
| 路线 | V45 Stage2 Wait Reduce |
| 工作频率 | 300 MHz |
| `cnt_test` | 85 |
| 理论时间 | 85 / 300 MHz = 0.283 us |
| WNS/TNS | +0.091 ns / 0.000 ns |
| WHS/THS | +0.127 ns / 0.000 ns |
| LUT/FF | 2228 / 1619 |
| DSP/BRAM | 0 / 0 |
| 官方样例 + 20 随机 | PASS |
| 上板状态 | YES |
| no-ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit` |

## 上板验证摘要

V45 已完成 no-ILA 下载和 ILA 调试验证。硬件目标为 `localhost:3121/xilinx_tcf/Digilent/210251A08870`，识别器件为 `xc7k160t_0`。ILA 抓取到 16 次 `verify_we` 写回，`verify_addr` 覆盖 0 到 15，`verify_vector_out` 与 `FFT_output.coe` 完全匹配。比对脚本输出 `compare_status=PASS`，`final_done_cnt_test=85`。

详细 trace 见 `results/final_verify_write_trace.csv` 和 `results/v45_hw_compare.csv`。

## ILA 说明

ILA 调试版只用于功能观察，因引入 debug hub、ILA RAM 和探针扇出，其实现 WNS 为 -0.068 ns，不作为最终速度成绩。正式速度、资源和上板展示均以 no-ILA bitstream 为准。

## 后续优化结论

V43 证明当前结构直接提升到 320 MHz 以上不可作为 timing-clean 成绩。V44 稳定化有小幅收益，但未超过 V45。V46 若继续推进 Stage1 分工，需要更多验证时间，答辩前建议保持 V45 为主路线，V42 为回退路线。
