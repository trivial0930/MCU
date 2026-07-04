# V42 路线记录：V34 已上板验证最终基线

## 定位

V42 直接继承 V34，不做任何行为优化。它用于把 V34 的上板证据、合规说明和可回退状态固定下来，避免后续 V43/V44/V45 等实验路线影响已验证基线。

## 继承自 V34 的事实

| 项目 | 结果 |
| --- | --- |
| 是否上板 | YES |
| 工作频率 | 300 MHz |
| `cnt_test` | 88 |
| 理论时间 | 0.293 us |
| no-ILA WNS/TNS | +0.056 ns / 0.000 ns |
| no-ILA WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF | 2228 / 1615 |
| DSP/BRAM | 0 / 0 |
| 官方样例 + 20 随机 | PASS |

## 上板验证摘要

V34/V42 已经使用 ILA 抓到 16 次 verify 写回，地址覆盖 0 到 15，最后写回地址为 15，所有 `verify_vector_out` 与 `FFT_output.coe` 一致。详细证据见 `board_validation/BOARD_VALIDATION.md` 和本路线新生成的 `BOARD_VERIFICATION_REPORT.md`。

## 后续关系

- V42 是最快已上板回退基线。
- V43 从 V42 复制，只做频率扫频。
- V44 从 V42 复制，只做稳定化/实现余量尝试。
- 若后续 V45/V46 更快但未上板，展示时仍以 V42 作为实物保底。
