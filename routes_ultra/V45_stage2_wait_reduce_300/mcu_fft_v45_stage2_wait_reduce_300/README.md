# V45：Stage2 Wait Reduce 300 MHz

V45 是 V38 的正式化版本，用来对应后续优化提示词中的 Stage2 wait reduce 任务。该路线保持双完整 MCU、普通 32-bit ARM-like 指令 ROM、DSP=0 和 no-ILA 统计口径，通过扫描 `CORE1_WAIT_STAGE2_NOP` 与最终 addr15 写回对齐延迟，将 `cnt_test` 从 V42/V34 的 88 降到 85。

## 关键结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 组随机输入 | PASS |
| 最小安全 `stage2_wait` | 68 |
| 最优 `final_addr15_delay` | 9 |
| `cnt_test` | 85 |
| 300 MHz 理论时间 | 0.283 us |
| no-ILA WNS/TNS | +0.091 ns / 0.000 ns |
| no-ILA WHS/THS | +0.127 ns / 0.000 ns |
| LUT/FF/DSP | 2228 / 1619 / 0 |
| 实物上板验证 | PASS |
| ILA 写回验证 | 16 次 verify 写回全匹配，地址 0..15 覆盖完整 |

V45 目前是仓库中最快的合规实现路线，也是已经完成实物上板验证的最快路线。最终演示时建议优先使用 no-ILA bitstream 展示速度和资源，用 ILA 证据说明写回结果正确。

## 复现命令

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
py scripts\sweep_stage2_wait.py
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v45_stable_no_ila.tcl
```

## 上板验证命令

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v45_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v45_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v45_ila_verify_we.tcl
py board_validation\compare_v45_ila_capture.py
```

最后已重新下载 no-ILA bitstream，开发板当前不保留 ILA 调试逻辑。

## 主要结果文件

- `results/sweep_stage2_wait.csv`
- `results/sweep_stage2_wait_summary.txt`
- `results/core_timeline_before.md`
- `results/regression_summary.txt`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `board_validation/no_ila_program_status.txt`
- `board_validation/capture_v45_ila_status.txt`
- `board_validation/v45_hw_compare_status.txt`
- `board_validation/v45_hw_compare.csv`
- `board_validation/BOARD_VALIDATION.md`

注意：ILA 调试版只用于抓取 `verify_we`、`verify_addr`、`verify_vector_out`、`cnt_test` 等波形。ILA 版引入调试核后 WNS 为 -0.068 ns，不作为最终速度和资源成绩；正式成绩以 no-ILA bitstream 的 timing-clean 报告为准。
