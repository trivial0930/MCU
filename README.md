# MCU FFT 路线 A 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU 实验中的 8 点定点复数 FFT 任务。项目核心不是直接例化 FFT IP，而是用一个轻量 MCU 执行汇编程序完成 FFT 计算，并围绕官方 2026 测试样例做功能验证、上板调试和速度路线比较。

## 当前状态

- `Baseline/` 保存基础 MCU FFT 工程。
- `materials/` 保存课程资料、K7EDAEVAL 引脚表和官方测试样例。
- `routes/` 保存路线 A 的多个独立候选版本，便于保留可用版本并隔离失败实验。
- 已验证的功能路线集中在 `speed_v6`、`speed_v7`、`speed_v7b`、`speed_v7c`。
- `speed_v8_high_freq_sweep` 和 `speed_v8_route_a_vivado_matrix` 提供 Vivado 高频时序/资源比较脚本。

本次 Windows 调试已找到 Vivado 2025.2（`D:\vivado\2025.2\Vivado\bin\vivado.bat`），Icarus Verilog 已安装到 `C:\iverilog\bin` 并加入用户 PATH，四条路线的本地 Verilog 回归均已 PASS。Vivado 目标器件和 license 也已补齐，`speed_v7_q7_narrow_mul` 已在 `xc7k325tffg676-2` 下完成综合、实现、DRC 和 bitstream。

重要更新：课程资料中的 K7EDAEVAL 引脚表与 `xc7k325tffg676-2` 匹配，不匹配此前文档中的 `xc7k325tffg900-2`。仓库脚本默认 part 已改为 `xc7k325tffg676-2`，并修正了 KEY1 所在 HP Bank 的 IOSTANDARD。上板前仍建议核对板卡 FPGA 丝印；若实物确为其他 package，需要重新核对引脚表。

## 推荐阅读顺序

1. `materials/README.md`：确认资料来源、官方输入输出样例和板卡引脚表。
2. `routes/README.md`：理解每条路线的目标、当前验证状态和后续选择标准。
3. `docs/上板与交接指南.md`：最新上板状态、bit/ltx 位置、报告摘要、重新生成命令和 ILA 观察步骤。
4. `WINDOWS_CODEX_HANDOFF.md`：在 Windows + Vivado + Codex 环境继续调试时的操作清单。
5. `routes/README.md`：理解每条路线的目标、当前验证状态和后续选择标准。

## 快速功能回归

需要安装 Python 与 Icarus Verilog，并确保 `iverilog`、`vvp` 在 PATH 中：

```powershell
py routes\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
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
cd routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```

比较时先看 `WNS >= 0` 的最高目标频率，再比较 `LUT`、`FF`、`DSP`、`BRAM`。最终成绩建议使用关闭 ILA 的实现结果。

单条推荐路线可以直接跑到 bitstream：

```powershell
cd routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
vivado -mode batch -source ../../vivado/run_board_bitstream.tcl
```

该脚本会运行综合、实现、DRC 和 `write_bitstream`，并把报告写入 `results/vivado_board/`。

## 上板入口

推荐先使用稳定的窄乘法路线：

```powershell
cd routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
vivado
```

Vivado Tcl Console 中执行：

```tcl
set PART_NAME xc7k325tffg676-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
source ../../vivado/create_board_project.tcl
```

首次上板重点观察：`done` 是否拉高、`verify_we` 是否产生 16 次写入、最后写地址是否为 15、`cnt_test` 是否接近 157、输出序列是否与 `mem/FFT_output.coe` 一致。

已生成的首板调试文件位于：

- `routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_ila.bit`
- `routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_ila.ltx`
- `routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul/results/vivado_board/board_top_no_ila.bit`
