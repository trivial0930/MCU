# speed_v8_route_a_vivado_matrix

目标：路线 A3/A4 的 Vivado 实现矩阵比较。

本目录把 Vivado 比较脚本和已验证 RTL 候选隔离开，比较对象包括：

- `speed_v6_official_sample`：通用 Q7 乘法。
- `speed_v7_q7_narrow_mul`：data x 8-bit coefficient 窄乘法。
- `speed_v7b_c91_shift_add`：常数 91 写成 `64 + 16 + 8 + 2 + 1`。
- `speed_v7c_c91_shift_sub`：常数 91 写成 `128 - 32 - 4 - 1`。

## 当前 Vivado 调试状态

本机已找到 Vivado 2025.2：`D:\vivado\2025.2\Vivado\bin\vivado.bat`。

根据课程引脚表和 Vivado package pin 检查，当前上板 part 使用：

```text
xc7k160tffg676-2
```

推荐首板路线 `speed_v7_q7_narrow_mul` 已完成目标 part 下的综合、实现、DRC 和 bitstream。矩阵目录用于比较路线 A 的高频余量。所有新 Vivado 脚本默认使用 `flatten_hierarchy=none` 和 `max_dsp=0`，以满足老师对层级资源统计和 MCU 不使用 DSP 的要求。

最新 post-route 榜单在 `results/leaderboard_summary.md`：

| 路线 | 最高通过频率 | WNS(ns) | LUT | FF | DSP |
| --- | ---: | ---: | ---: | ---: | ---: |
| `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 549 | 0 |
| `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 549 | 0 |
| `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 549 | 0 |
| `speed_v6_official_sample` | 未通过 95 MHz | -0.162 | 1704 | 549 | 0 |

早期 synth-only 冒烟结果已经删除，避免把未加载板级 XDC 或旧 DSP 口径的数据误当正式成绩。

## 跑最终实现矩阵

运行：

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
