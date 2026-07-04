# 路线 B 结果目录说明

本目录保存路线 B 的机器可读结果、Vivado 解析结果和排行榜。当前已经确认的是 B1 到 B4 的功能回归；Vivado 矩阵脚本已经补齐，后续运行后会在本目录生成速度/效率榜。

## 当前已确认结果

`route_b_summary.csv` 是当前路线 B 的功能回归汇总，字段含义如下：

| 字段 | 说明 |
| --- | --- |
| `route` | 路线 B 子方案名。 |
| `project` | 对应工程目录。 |
| `instruction_count` | 当前 FFT 程序指令条数。 |
| `cnt_test` | 测试窗口内 MCU 执行周期数。 |
| `official_sample` | 官方样例是否通过。 |
| `random_cases` | 已跑随机用例数量。 |
| `seed_range` | 随机种子范围。 |
| `current_status` | 当前判断。 |
| `next_action` | 后续建议。 |

当前功能结论：B1、B2、B3、B4 均已通过官方样例和 20 组随机回归。

## Vivado 矩阵结果生成

在 `routesB` 目录运行：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_routesB_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_b_matrix.csv
py scripts\make_leaderboards.py --in-csv results\route_b_matrix.csv --summary-csv results\route_b_summary.csv --out-dir results
```

生成文件：

| 文件 | 用途 |
| --- | --- |
| `route_b_matrix.csv` | Vivado post-route 原始汇总。 |
| `route_b_speed_leaderboard.csv` | 只看可通过最高频率的速度榜。 |
| `route_b_time_leaderboard.csv` | 按 `cnt_test / Fmax` 排序的真实耗时榜。 |
| `route_b_efficiency_leaderboard.csv` | 综合考虑 LUT、FF、BRAM 后的效率榜。 |

只有 `official_sample=PASS`、post-route `WNS >= 0` 且 `DSP=0` 的结果才能进入最终可选路线。若打开 ILA 生成 bitstream，资源和时序只能作为调试参考；最终排行榜应使用关闭 ILA 的实现结果。

## 当前推荐判断

- B4：最低风险，适合作为路线 B 首个上板验证对象。
- B3：周期收益和时序压力折中，最值得优先跑 Vivado 矩阵。
- B2：用于验证“减少融合点是否换来更高 Fmax”。
- B1：`cnt_test` 最低，但关键路径最长，适合在 B3/B2 结果明确后继续优化。
