# MCU FFT 路线 A 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU 实验中的 8 点定点复数 FFT 任务。项目核心不是直接例化 FFT IP，而是用一个轻量 MCU 执行汇编程序完成 FFT 计算，并围绕官方 2026 测试样例做功能验证、上板调试和速度路线比较。

## 当前状态

- `Baseline/` 保存基础 MCU FFT 工程。
- `materials/` 保存课程资料、K7EDAEVAL 引脚表和官方测试样例。
- `routes/` 保存路线 A 的多个独立候选版本，便于保留可用版本并隔离失败实验。
- 已验证的功能路线集中在 `speed_v6`、`speed_v7`、`speed_v7b`、`speed_v7c`。
- `speed_v8_high_freq_sweep` 和 `speed_v8_route_a_vivado_matrix` 提供 Vivado 高频时序/资源比较脚本。

本次 Windows 调试已找到 Vivado 2025.2（`D:\vivado\2025.2\Vivado\bin\vivado.bat`），并用已安装的 `xc7k160tffg676-2` 跑通四条路线的综合冒烟；结果见 `routes/speed_v8_route_a_vivado_matrix/results/synth_smoke_preboard_matrix.csv`。Icarus Verilog 已安装到 `C:\iverilog\bin` 并加入用户 PATH，四条路线的本地 Verilog 回归均已 PASS。

当前唯一阻塞项是 Vivado 安装缺少目标板卡默认器件 `xc7k325tffg900-2`。本机 `get_parts xc7k325tffg900-2` 返回 0，安装日志显示当前只安装了 `xc7k70t`、`xc7k160t`、`xc7k160ti` 等 Kintex-7 器件。需要用管理员权限打开 `Add Design Tools or Devices 2025.2` 补齐 Kintex-7 7K325 器件支持后，才能完成 K7EDAEVAL 的 post-route 时序矩阵、DRC 和 bitstream。

## 推荐阅读顺序

1. `materials/README.md`：确认资料来源、官方输入输出样例和板卡引脚表。
2. `routes/README.md`：理解每条路线的目标、当前验证状态和后续选择标准。
3. `routes/ROUTE_A_BOARD_BRINGUP_GUIDE.md`：按步骤完成 Vivado 建工程、综合实现、上板和 ILA 观察。
4. `WINDOWS_CODEX_HANDOFF.md`：在 Windows + Vivado + Codex 环境继续调试时的操作清单。
5. `docs/README.md`：文档入口，指向当前状态报告、上板前检查记录和后续上板指南。
6. `docs/后续操作与上板指南.md`：从当前综合冒烟结果继续到最终实现矩阵和上板验收的完整中文指南。

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

补齐 `xc7k325tffg900-2` 后，单条推荐路线可以直接跑到 bitstream：

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
set PART_NAME xc7k325tffg900-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
source ../../vivado/create_board_project.tcl
```

首次上板重点观察：`done` 是否拉高、`verify_we` 是否产生 16 次写入、最后写地址是否为 15、`cnt_test` 是否接近 157、输出序列是否与 `mem/FFT_output.coe` 一致。
