# V56 八核 bucketed output-owner 路线

V56 从 V54 八核 output-owner 路线继续优化。八个完整 MCU core 仍分别负责 `X0..X7` 的实部和虚部输出，输入读取、计算和 verify 写回均由普通指令完成。

## 当前结果

| 项目 | 结果 |
| --- | --- |
| 来源路线 | V54 |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 54 |
| 300 MHz 理论时间 | 0.180 us |
| 指令总数 | 356 |
| DSP | 0 |
| Vivado 状态 | 未单独作为最终候选实现，后续 V59 已超过 |

## 核心改动

V54 的奇数输出核在处理 `±91` 系数时存在重复乘法。V56 将这些项先按 real bucket 和 imag bucket 聚合，然后每个奇数核只保留两条普通 `MUL` 指令。

这不是新增专用硬件，也不是新增专用指令；所有变换仍由 `LDR/ADD/SUB/MUL/STR` 指令序列完成。

## 复现命令

```powershell
cd routes_ultra\V56_octa_bucketed_output_owner_300\mcu_fft_v56_octa_bucketed_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\octa_audit.py
```
