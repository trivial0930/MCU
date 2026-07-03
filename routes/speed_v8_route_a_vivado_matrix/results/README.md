# Vivado 结果文件说明

本目录只保存适合进入 GitHub 的汇总结果。完整 Vivado 工程、中间 DCP、日志和 `.Xil` 缓存位于 `build/`，默认不提交。

| 文件 | 含义 |
| --- | --- |
| `route_a_matrix_template.csv` | 最终 post-route 矩阵的模板。需要继续比较多路线高频余量时生成 `route_a_matrix.csv`。 |
| `synth_smoke_matrix.csv` | 初次综合冒烟汇总，使用替代器件 `xc7k160tffg676-2`，不加载板级 XDC。 |
| `synth_smoke_preboard_matrix.csv` | 安装 Icarus、刷新初始化文件后重新跑的上板前综合冒烟汇总。 |

当前首板推荐路线已经在 `speed_v7_q7_narrow_mul` 下完成 bitstream。本目录保留矩阵脚本，用于后续继续比较 v6/v7/v7b/v7c。运行方式：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```
