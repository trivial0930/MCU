# V56 路线说明

## 来源

V56 复制自 `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300`。

## 优化目标

在不增加核数、不增加专用 FFT 硬件、不增加专用指令的前提下，减少奇数输出核的普通指令数量，使八核 output-owner 路线继续低于 V54 的 `cnt_test=59`。

## 实现内容

- 保持 Core0..Core7 八个完整 MCU core。
- 保持每个 core 独立指令 ROM 和复制后的 test ROM 读取端口。
- 对奇数输出 `X1/X3/X5/X7` 中的 `±91` 系数项做 bucket 聚合。
- real bucket 使用 `R14`，imag bucket 使用 `R15`。
- 每个奇数核最终只用两条普通 `MUL` 完成 `×91` 缩放。
- verify RAM 仍由普通 `STR` 指令写入。

## 结果

| 项目 | V54 | V56 |
| --- | ---: | ---: |
| `cnt_test` | 59 | 54 |
| 300 MHz 理论时间 | 0.197 us | 0.180 us |
| 指令总数 | 452 | 356 |
| 官方样例 + 20 随机 | PASS | PASS |
| DSP | 0 | 0 |

V56 是有效功能优化，但后续 V57/V58/V59 已继续超过它，因此不建议作为最终上板主线。
