# MCU FFT 路线 A 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU 实验中的 8 点定点复数 FFT 任务。项目核心不是直接例化 FFT IP，而是用一个轻量 MCU 执行汇编程序完成 FFT 计算，并围绕官方 2026 测试样例做功能验证、上板调试和速度路线比较。

## 当前状态

- `materials/` 保存课程资料、K7EDAEVAL 引脚表和官方测试样例。
- `routesA/` 保存路线 A 的多个独立候选版本，便于保留可用版本并隔离失败实验。
- 已验证的功能路线集中在 `speed_v6`、`speed_v7`、`speed_v7b`、`speed_v7c`。
- `speed_v8_high_freq_sweep` 和 `speed_v8_route_a_vivado_matrix` 提供 Vivado 高频时序/资源比较脚本。
- `RESULTS.md` 汇总当前速度榜、效率榜、推荐路线和上板交付物。
- `routesB/` 保存路线 B 的 B1 到 B4 独立候选方案，当前功能回归通过，Vivado 矩阵和排行榜脚本已补齐。
- `routes_ultra/` 保存 300 MHz 极限路线，当前最快为 `V22b_fast_mul2_300`，已完成 300 MHz timing-clean bitstream。

本次 Windows 调试已找到 Vivado 2025.2（`D:\vivado\2025.2\Vivado\bin\vivado.bat`），Icarus Verilog 已安装到 `C:\iverilog\bin` 并加入用户 PATH，四条路线的本地 Verilog 回归均已 PASS。Vivado 目标器件和 license 也已补齐，`speed_v7_q7_narrow_mul` 已按课件确认的 `xc7k160tffg676-2` 完成综合、实现、DRC 和 bitstream。

最新上板结果：`speed_v7_q7_narrow_mul` 已通过 `PLLE2_BASE` 将板载 50 MHz 倍频到 130 MHz，实物上板验证通过。无 ILA 正式版本 post-route WNS 为 `0.190 ns`，`cnt_test=157`，测试窗口约 `1.208 us`，DSP 为 0。带 ILA 版本仅用于抓波，已确认 16 次写回全部与 `FFT_output.coe` 匹配；最终板卡已切回无 ILA bitstream。

Ultra 最新结果：`routes_ultra/V22b_fast_mul2_300` 已在 300 MHz 下完成官方样例 + 20 组随机回归、Vivado 实现、DRC 和 bitstream，`cnt_test=173`，按 300 MHz 推算约 `0.577 us`，post-route WNS 为 `+0.122 ns`，DSP=0。`routes_ultra/V19_pipeline_300` 已完成实物上板验证，仍可作为 300 MHz 稳健保底路线。

重要更新：课件 `materials/source_docs/Lab1.pdf` 写明实验板 FPGA 为 `XC7K160T-2FFG676-I`，Vivado part 为 `xc7k160tffg676-2`。仓库脚本默认 part 已改为 `xc7k160tffg676-2`，综合默认 `flatten_hierarchy=none`、`max_dsp=0`，最新无 ILA 和带 ILA 报告中 `DSPs=0`。上板前仍建议核对板卡 FPGA 丝印；若实物确为其他 package，需要重新核对 XDC。

## 推荐阅读顺序

1. `materials/README.md`：确认资料来源、官方输入输出样例和板卡引脚表。
2. `RESULTS.md`：查看当前速度榜、效率榜和推荐上板路线。
3. `routes_ultra/README.md`：查看 300 MHz 极限路线、V22b 速度榜和 bitstream 位置。
4. `docs/上板与交接指南.md`：最新上板状态、bit/ltx 位置、报告摘要、重新生成命令和 ILA 观察步骤。
5. `routesA/README.md`：理解每条路线的目标、当前验证状态和后续选择标准。
6. `WINDOWS_CODEX_HANDOFF.md`：在 Windows + Vivado + Codex 环境继续调试时的操作清单。

## 快速功能回归

需要安装 Python 与 Icarus Verilog，并确保 `iverilog`、`vvp` 在 PATH 中：

```powershell
py routesA\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

该命令会依次检查四条路线：

- `speed_v6_official_sample`
- `speed_v7_q7_narrow_mul`
- `speed_v7b_c91_shift_add`
- `speed_v7c_c91_shift_sub`

如果缺少 Icarus Verilog，脚本会在运行前退出，不会刷新各路线下的 `results/route_a_regression.log`。

## Vivado 路线比较

在安装 Vivado 的 Windows 机器上运行：

```powershell
cd routesA\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
py scripts\make_leaderboards.py --in-csv results\route_a_matrix.csv
```

比较时先看 `WNS >= 0` 的最高目标频率，再比较 `LUT`、`FF`、`DSP`、`BRAM`。最终成绩建议使用关闭 ILA 的实现结果。

已生成榜单可直接查看：

- `RESULTS.md`
- `routesA/speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`
- `routesA/speed_v8_route_a_vivado_matrix/results/speed_leaderboard.csv`
- `routesA/speed_v8_route_a_vivado_matrix/results/efficiency_leaderboard.csv`

单条推荐路线可以直接跑到 bitstream：

```powershell
cd routesA\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
vivado -mode batch -source ../../vivado/run_board_bitstream.tcl
```

该脚本会运行综合、实现、DRC 和 `write_bitstream`，并把报告写入 `results/vivado_board/`。

## 上板入口

推荐先使用稳定的窄乘法路线：

```powershell
cd routesA\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
vivado
```

Vivado Tcl Console 中执行：

```tcl
set PART_NAME xc7k160tffg676-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0
source ../../vivado/create_board_project.tcl
```

首次上板重点观察：`done` 是否拉高、`verify_we` 是否产生 16 次写入、最后写地址是否为 15、`cnt_test` 是否接近 157、输出序列是否与 `mem/FFT_output.coe` 一致。

已生成的首板调试文件位于：

- `routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_ila.bit`
- `routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_ila.ltx`
- `routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_no_ila.bit`

130 MHz PLL 实物上板交付物位于本地 `output/hardware_debug/routeA_130MHz_PLL_20260704/`，PDF 报告位于本地 `output/pdf/RouteA_130MHz_PLL_board_report.pdf`。`output/` 目录按仓库规则不提交到 GitHub，GitHub 中保留源码、脚本、报告摘要和 Vivado 文本报告。
