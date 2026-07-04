# Vivado 结果文件说明

本目录只保存适合进入 GitHub 的汇总结果。完整 Vivado 工程、中间 DCP、日志和 `.Xil` 缓存位于 `build/`，默认不提交。

| 文件 | 含义 |
| --- | --- |
| `route_a_matrix.csv` | 最新 K160、`flatten_hierarchy=none`、`max_dsp=0` 的 20 组 post-route 矩阵结果。 |
| `speed_leaderboard.csv` | 每条路线的速度榜，按最高通过频率排序，并保留未通过路线说明。 |
| `efficiency_leaderboard.csv` | 效率榜，按 `MHz/LUT` 排序，只统计 `WNS>=0` 且 `DSP=0` 的组合。 |
| `leaderboard_summary.md` | 速度榜和效率榜的中文摘要。 |

当前首板推荐路线已经在 `speed_v7_q7_narrow_mul` 下完成 K160、`flatten_hierarchy=none`、`max_dsp=0` 的 bitstream。本目录保留矩阵脚本，用于后续继续比较 v6/v7/v7b/v7c。运行方式：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
py scripts\make_leaderboards.py --in-csv results\route_a_matrix.csv
```

早期 synth-only 冒烟 CSV 已删除；正式比较只保留 post-route 结果，避免把未加载板级 XDC 或未使用最终 `max_dsp=0` 口径的数据误当成绩。
