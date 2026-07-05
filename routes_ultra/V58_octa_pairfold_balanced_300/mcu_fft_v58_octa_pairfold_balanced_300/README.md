# V58 八核 pair-fold balanced 路线

V58 从 V57 继续配平奇数输出核，去掉 `X3/X5` 中额外的取负路径，使四个奇数核均为 46 条指令。

## 当前结果

| 项目 | 结果 |
| --- | --- |
| 来源路线 | V57 |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 50 |
| 300 MHz 理论时间 | 0.167 us |
| 指令总数 | 340 |
| 奇数核指令数 | Core1/Core3/Core5/Core7 均为 46 |
| DSP | 0 |
| Vivado 状态 | 作为 V59 的功能基线，未单独作为最终候选实现 |

## 复现命令

```powershell
cd routes_ultra\V58_octa_pairfold_balanced_300\mcu_fft_v58_octa_pairfold_balanced_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\octa_audit.py
```
