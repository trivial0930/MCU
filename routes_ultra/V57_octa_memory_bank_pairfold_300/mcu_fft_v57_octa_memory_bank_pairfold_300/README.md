# V57 八核 pair-fold 路线

V57 从 V56 继续优化奇数输出核。核心思想是把 `±91` 相关的两组输入 pair 先做 fold，减少 bucket 形成过程中的 `ADD/SUB` 指令。

## 当前结果

| 项目 | 结果 |
| --- | --- |
| 来源路线 | V56 |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 52 |
| 300 MHz 理论时间 | 0.173 us |
| 指令总数 | 346 |
| DSP | 0 |
| Vivado 状态 | 未单独作为最终候选实现，后续 V59 已超过 |

## 复现命令

```powershell
cd routes_ultra\V57_octa_memory_bank_pairfold_300\mcu_fft_v57_octa_memory_bank_pairfold_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\octa_audit.py
```
