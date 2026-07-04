# V46：Stage1 Split Dual MCU 300 MHz

V46 从 V45 复制，用于探索“让 Core1 更早参与 Stage1”的下一步优化。该路线保持双完整 MCU、普通 32-bit ARM-like 指令 ROM、DSP=0 和 no-ILA 统计口径。

## 核心变化

- Core0 保留主计算链和 Stage1 上半支路。
- Core0 通过普通 `STR` 把 `x1/x5/x3/x7` 原始输入转交到 `RAM20..27`。
- Core1 通过普通 `LDR/SUB/ADD/MUL/STR` 计算 `(1,5,W1)` 与 `(3,7,W3)` 的下半支路。
- Core1 自己产生 `RAM10/RAM11/RAM14/RAM15`，因此 Stage2 wait 从 V45 的 68 降到 0。
- 为避免 addr15 过早写导致假停表，`final_addr15_delay` 必须从 V45 的 9 增加到 21。

## 关键结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 随机输入 | PASS |
| `CORE1_WAIT_STAGE1_RAW_NOP` | 12 |
| `CORE1_WAIT_STAGE2_NOP` | 0 |
| `CORE1_WAIT_STAGE3_NOP` | 0 |
| `final_addr15_delay` | 21 |
| `cnt_test` | 85 |
| 300 MHz 理论时间 | 0.283 us |
| no-ILA WNS/TNS | +0.029 ns / 0.000 ns |
| no-ILA WHS/THS | +0.119 ns / 0.000 ns |
| LUT/FF/DSP | 2231 / 1629 / 0 |
| 结论 | 合规可行，但没有超过 V45 |

## 复现命令

```powershell
cd routes_ultra\V46_stage1_split_dual_mcu_300\mcu_fft_v46_stage1_split_dual_mcu_300
py scripts\sweep_v46_stage1_split.py --random-cases 20 --seed 2026
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v46_no_ila.tcl
```

## 主要结果文件

- `ROUTE_NOTES.md`
- `results/stage1_dependency_graph.md`
- `results/core_timeline_before.md`
- `results/core1_wait_analysis.md`
- `results/core_timeline_after.md`
- `results/v46_stage1_split_sweep.csv`
- `results/verify_write_trace.csv`
- `results/opcode_summary.csv`
- `results/regression_summary.txt`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`

V46 不建议替代 V45。它的价值是证明最小 Stage1 下半支路迁移不会带来速度收益，下一步若继续探索，需要更深地移动 Core0 后半输出链或重新安排停表路径。
