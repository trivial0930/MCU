# V58 路线说明

## 来源

V58 复制自 `routes_ultra/V57_octa_memory_bank_pairfold_300/mcu_fft_v57_octa_memory_bank_pairfold_300`。

## 实现内容

- 保留 V57 的 pair-fold 方案。
- 重新整理 `X3/X5` 的符号表达式，避免额外 `MOVI R0,#0` 和取负 `SUB`。
- 将四个奇数输出核全部配平到 46 条指令。
- 偶数输出核保持 39 条指令。

## 结果

| 项目 | V57 | V58 |
| --- | ---: | ---: |
| `cnt_test` | 52 | 50 |
| 300 MHz 理论时间 | 0.173 us | 0.167 us |
| 指令总数 | 346 | 340 |
| 官方样例 + 20 随机 | PASS | PASS |
| DSP | 0 | 0 |

V58 是干净的功能基线，后续 V59 只在停表路径上进一步减少 1 个 `cnt_test`。
