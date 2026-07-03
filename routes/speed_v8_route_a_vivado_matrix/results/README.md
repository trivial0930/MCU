# Vivado 结果文件说明

本目录只保存适合进入 GitHub 的汇总结果。完整 Vivado 工程、中间 DCP、日志和 `.Xil` 缓存位于 `build/`，默认不提交。

| 文件 | 含义 |
| --- | --- |
| `route_a_matrix_template.csv` | 最终 post-route 矩阵的模板。目标器件可用后应生成 `route_a_matrix.csv`。 |
| `synth_smoke_matrix.csv` | 初次综合冒烟汇总，使用替代器件 `xc7k160tffg676-2`，不加载板级 XDC。 |
| `synth_smoke_preboard_matrix.csv` | 安装 Icarus、刷新初始化文件后重新跑的上板前综合冒烟汇总。 |

当前还没有 `route_a_matrix.csv`，原因是本机 Vivado 无法识别目标板卡器件：

```text
xc7k325tffg900-2
```

补齐器件包/license 后，在 `routes/speed_v8_route_a_vivado_matrix` 下运行：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```

