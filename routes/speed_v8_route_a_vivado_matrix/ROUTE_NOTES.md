# speed_v8_route_a_vivado_matrix

目标：路线 A3/A4 的 Vivado 实现矩阵比较。

本目录把 Vivado 比较脚本和已验证 RTL 候选隔离开，比较对象包括：

- `speed_v6_official_sample`：通用 Q7 乘法。
- `speed_v7_q7_narrow_mul`：data x 8-bit coefficient 窄乘法。
- `speed_v7b_c91_shift_add`：常数 91 写成 `64 + 16 + 8 + 2 + 1`。
- `speed_v7c_c91_shift_sub`：常数 91 写成 `128 - 32 - 4 - 1`。

## 当前 Vivado 调试状态

本机已找到 Vivado 2025.2：`D:\vivado\2025.2\Vivado\bin\vivado.bat`。

当前安装缺少目标板卡默认器件 `xc7k325tffg900-2`，`get_parts *k325*`
为空；安装中可用的 Kintex-7 主要是 `xc7k160t...`、`xc7k70t...`。因此
不能在本机生成可作为 K7EDAEVAL 最终依据的 post-route 时序矩阵。

为继续排查 HDL 和 Vivado 工程问题，已使用可用器件
`xc7k160tffg676-2` 跑过不加载板级 XDC 的综合冒烟：

```powershell
subst M: C:\Users\戎择辰\OneDrive\文档\数电实验\MCU
cd M:\routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_synth_smoke.tcl
```

结果已汇总到 `results/synth_smoke_matrix.csv`：

| 路线 | LUT | FF | DSP | BRAM | 结论 |
| --- | ---: | ---: | ---: | ---: | --- |
| `speed_v6_official_sample` | 886 | 552 | 4 | 0 | 综合通过 |
| `speed_v7_q7_narrow_mul` | 864 | 552 | 1 | 0 | 综合通过 |
| `speed_v7b_c91_shift_add` | 986 | 552 | 0 | 0 | 综合通过 |
| `speed_v7c_c91_shift_sub` | 949 | 552 | 0 | 0 | 综合通过 |

这些数据只用于综合级冒烟和资源趋势判断，不能替代目标板卡 part + XDC
下的实现时序。当前趋势是：v7 窄乘法 LUT 最低且只用 1 个 DSP；v7b/v7c
省掉 DSP，但 LUT 增加。

## 跑最终实现矩阵

在安装了 `xc7k325tffg900-2` 器件支持和有效 license 的 Vivado 环境中运行：

```powershell
cd routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```

若在中文或较长路径下运行 Vivado 不稳定，优先用 `subst` 映射短路径：

```powershell
subst M: C:\Users\戎择辰\OneDrive\文档\数电实验\MCU
cd M:\routes\speed_v8_route_a_vivado_matrix
```

最终路线选择仍应以 post-route `WNS`、`LUT`、`FF`、`DSP`、`BRAM` 为准。
