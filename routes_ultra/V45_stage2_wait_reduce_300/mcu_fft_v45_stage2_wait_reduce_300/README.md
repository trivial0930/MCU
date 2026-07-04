# V45：Stage2 Wait Reduce 300 MHz

V45 是 V38 的正式化版本，用来对应后续路线提示词中的 “Stage2 wait reduce” 任务。本路线保持双完整 MCU、普通 32-bit ARM-like 指令 ROM、DSP=0 和 no-ILA 官方统计口径，通过扫描 `CORE1_WAIT_STAGE2_NOP` 与最终 addr15 对齐延迟，将 `cnt_test` 从 V42/V34 的 88 降到 85。

关键结果：

- 官方样例 + 20 组随机输入：PASS。
- 最小安全 `stage2_wait=68`。
- 最佳 `final_addr15_delay=9`。
- `cnt_test=85`。
- 300 MHz no-ILA timing-clean，WNS `+0.091 ns`。
- LUT/FF/DSP：2228 / 1619 / 0。
- verify 写回 16 次，最终可信写回为 addr15。
- 尚未独立上板；当前最快已上板路线仍为 V42/V34。

复现命令：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
py scripts\sweep_stage2_wait.py
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v45_stable_no_ila.tcl
```

主要结果文件：

- `results/sweep_stage2_wait.csv`
- `results/sweep_stage2_wait_summary.txt`
- `results/core_timeline_before.md`
- `results/regression_summary.txt`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`

展示建议：V45 是当前最快合规实现候选，但没有上板证据。答辩时如只展示实物验证成绩，应使用 V42；如展示“最新优化潜力”，可展示 V45 并明确标注尚未上板。
