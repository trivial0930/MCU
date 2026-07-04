# V49：最终上板与答辩证据包

V49 汇总当前可用于答辩的证据。最新结论是：V45 已完成开发、回归、300 MHz no-ILA 实现、ILA 抓波验证和最终 no-ILA 重新下载，因此 V45 是当前最快且已上板的主展示路线；V42/V34 保留为稳定回退路线。

## 核心结论

- 最快已上板路线：V45，300 MHz，`cnt_test=85`，理论时间约 0.283 us。
- V45 no-ILA WNS/TNS：`+0.091 ns / 0.000 ns`，WHS/THS：`+0.127 ns / 0.000 ns`，DSP=0。
- V45 ILA 已验证 16 次 verify 写回，地址 0..15 覆盖完整，输出与 `FFT_output.coe` 一致，最终 `cnt_test=85`。
- ILA 调试版 WNS 为 -0.068 ns，只作为抓波证据；正式速度和资源以 no-ILA bitstream 为准。
- V42/V34：300 MHz，`cnt_test=88`，WNS `+0.056 ns`，DSP=0，作为稳定回退路线。
- V43 高频扫频显示 320/333/350 MHz setup timing 不通过，340/360 MHz 受 PLLE2 VCO 范围限制。
- V44 稳定化最优 WNS 为 `+0.069 ns`，未替代 V45。

## 文档入口

- `FINAL_REPORT.md`
- `BOARD_VERIFICATION_REPORT.md`
- `ARCH32_COMPLIANCE_REPORT.md`
- `DUAL_OR_MULTI_MCU_COMPLIANCE_REPORT.md`
- `PERFORMANCE_SUMMARY.md`
- `RISK_AND_FALLBACK.md`

## 关键结果文件

- `results/final_verify_write_trace.csv`
- `results/final_timing_summary.txt`
- `results/final_utilization_summary.txt`
- `results/final_regression_summary.txt`
- `results/v45_no_ila_program_status.txt`
- `results/v45_ila_capture_status.txt`
- `results/v45_hw_compare_status.txt`
- `results/v45_hw_compare.csv`
- `results/v45_ila_timing_summary.txt`
- `results/v45_ila_utilization_summary.txt`
- `results/v43_freq_sweep.csv`
- `results/v44_timing_compare.csv`
- `results/v45_stage2_wait_summary.txt`
- `results/v45_timing_summary.txt`
