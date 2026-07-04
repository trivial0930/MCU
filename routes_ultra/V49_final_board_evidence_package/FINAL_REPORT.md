# 最终报告

## 最终展示路线

当前最终实物展示路线为 `V42_v34_board_verified_300/mcu_fft_v42_v34_board_verified_300`。

选择原因：V42 继承已经上板验证的 V34，不改变 RTL 行为和指令流，并补齐了上板证据、合规说明、反汇编和 verify 写回 trace。它不是仓库里理论最快的路线，但它是当前最快的已上板路线。

## 核心指标

| 项目 | 结果 |
| --- | --- |
| 路线 | V42/V34 board verified baseline |
| 工作频率 | 300 MHz |
| `cnt_test` | 88 |
| 理论时间 | 88 / 300 MHz = 0.293 us |
| WNS/TNS | +0.056 ns / 0.000 ns |
| WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF | 2228 / 1615 |
| DSP/BRAM | 0 / 0 |
| 官方样例 + 20 随机 | PASS |
| 上板状态 | YES |
| no-ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v42_v34_board_verified_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## 上板验证摘要

V42/V34 已完成 ILA 观察和 no-ILA 下载验证。ILA 捕获到 16 次 `verify_we` 写回，`verify_addr` 覆盖 0 到 15，最后可信写回地址为 15，`verify_vector_out` 与 `FFT_output.coe` 匹配。

详细 trace 见 `results/final_verify_write_trace.csv`。

## 后续优化结论

V43：直接提高频率不可作为有效成绩。300 MHz 通过；320/333/350 MHz 均生成 bitstream 但 WNS 为负；340/360 MHz 受 PLL VCO 范围限制。

V44：300 MHz 稳定化有小幅收益，最佳 WNS `+0.069 ns`，但未达到 `+0.100 ns` 目标。

V45：Stage2 wait reduce 已正式化，`cnt_test=85`，300 MHz WNS `+0.091 ns`，DSP=0，官方 +20 随机 PASS；但尚未上板，暂不能替代 V42 的实物展示结论。
