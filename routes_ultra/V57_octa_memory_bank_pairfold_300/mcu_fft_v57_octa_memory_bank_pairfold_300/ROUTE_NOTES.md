# V57 路线说明

## 来源

V57 复制自 `routes_ultra/V56_octa_bucketed_output_owner_300/mcu_fft_v56_octa_bucketed_output_owner_300`。

## 实现内容

- 保留 V56 的八核 output-owner 架构。
- 继续保持奇数核每核两条普通 `MUL`。
- 将 `±91` 的两个 pair 组合成更短的 fold 形式。
- Core1/Core7 缩短到 47 条指令，Core3/Core5 缩短到 48 条指令。

## 结果

| 项目 | V56 | V57 |
| --- | ---: | ---: |
| `cnt_test` | 54 | 52 |
| 300 MHz 理论时间 | 0.180 us | 0.173 us |
| 指令总数 | 356 | 346 |
| 官方样例 + 20 随机 | PASS | PASS |
| DSP | 0 | 0 |

V57 证明 pair-fold 方向有效，但 Core3/Core5 仍比 Core1/Core7 多一条取负相关指令，因此继续进入 V58 配平。
