# V44 稳定化实现报告

V44 继承 V42/V34 的 88cnt 双 MCU 路线，不改变 RTL 功能和指令流。本轮只比较 Vivado no-ILA 300 MHz 实现策略。

## 实现策略结果

| 变体 | WNS | TNS | WHS | LUT | FF | DSP | 结论 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| postroute_physopt | 0.056 | 0.000 | 0.085 | 2226 | 1618 | 0 | timing_clean_dsp0 |
| netdelay_high | 0.061 | 0.000 | 0.127 | 2216 | 1613 | 0 | timing_clean_dsp0 |
| retiming_try | 0.069 | 0.000 | 0.085 | 2224 | 1608 | 0 | timing_clean_dsp0 |

## 与 V42 对比

V42 baseline: WNS 0.056 ns, WHS 0.085 ns, LUT/FF 2228/1615, DSP 0。
V44 最优变体为 `retiming_try`：WNS 0.069 ns，相对 V42 变化 +0.013 ns，DSP 0。
结论：V44 仍满足 300 MHz 时序，但未达到 +0.100 ns 余量目标，暂不替代 V42。

详细最差路径见 `results/worst_path_before.txt` 和 `results/worst_path_after.txt`。
