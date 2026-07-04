# V49：最终上板与答辩证据包

V49 汇总当前可用于答辩的证据。当前最终实物展示路线选择 V42/V34，因为它是最快且已经完成开发板验证的路线；V45 是当前最快未上板候选，不能替代 V42 的实物结论。

核心结论：

- 最快已上板路线：V42/V34，300 MHz，`cnt_test=88`，理论时间约 0.293 us。
- V42 no-ILA WNS/TNS：`+0.056 ns / 0.000 ns`，DSP=0。
- V42 ILA 已验证 16 次 verify 写回，最终可信写回为 addr15，输出与 `FFT_output.coe` 一致。
- 最快未上板候选：V45，300 MHz，`cnt_test=85`，理论时间约 0.283 us，WNS `+0.091 ns`，DSP=0。
- V43 高频扫频显示：320/333/350 MHz 能生成 bitstream 但 setup timing 不通过；340/360 MHz 受 PLLE2 VCO 范围限制。
- V44 稳定化最佳 WNS 为 `+0.069 ns`，未达到 `+0.100 ns` 目标。

文档入口：

- `FINAL_REPORT.md`
- `BOARD_VERIFICATION_REPORT.md`
- `ARCH32_COMPLIANCE_REPORT.md`
- `DUAL_OR_MULTI_MCU_COMPLIANCE_REPORT.md`
- `PERFORMANCE_SUMMARY.md`
- `RISK_AND_FALLBACK.md`

关键结果：

- `results/final_opcode_summary.csv`
- `results/final_verify_write_trace.csv`
- `results/final_timing_summary.txt`
- `results/final_utilization_summary.txt`
- `results/final_regression_summary.txt`
- `results/v43_freq_sweep.csv`
- `results/v44_timing_compare.csv`
- `results/v45_stage2_wait_summary.txt`
- `results/v45_timing_summary.txt`
