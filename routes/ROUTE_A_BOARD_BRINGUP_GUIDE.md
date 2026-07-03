# 路线 A 上板与 Vivado 调试指南

本文面向 `routes/` 下的路线 A 候选工程：

- `speed_v6_official_sample/mcu_fft_official_sample`
- `speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul`
- `speed_v7b_c91_shift_add/mcu_fft_c91_shift_add`
- `speed_v7c_c91_shift_sub/mcu_fft_c91_shift_sub`

推荐先用 `speed_v7_q7_narrow_mul` 上板。它保留通用 Q7 乘法语义，又比 v6 的乘法实现更窄，通常是功能风险和速度收益之间更稳的起点。

## 1. 上板前检查

进入候选路线工程根目录，例如：

```powershell
cd routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
```

如果安装了 Icarus Verilog，先跑功能回归：

```powershell
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

期望看到：

```text
official_sample PASS
random_seed_2045 PASS
```

该命令会刷新或生成以下上板也会用到的初始化文件：

- `mem/FFT_input.mem`
- `mem/instr_fft8.mem`
- `mem/instr_fft8.coe`

如果没有 `iverilog` 和 `vvp`，脚本会提前退出。此时可以跳过本地仿真，但不要把这个退出当成 HDL 失败。

## 2. 时钟边界

当前板级顶层 `rtl/board_top.v` 直接使用 K7EDAEVAL 的 50 MHz 输入时钟：

```verilog
assign clk = CLK_50M;
```

因此直接下载 bitstream 时，板上真实运行频率是 50 MHz。`speed_v8` 中的 95/100/110/120/130 MHz 是 Vivado 实现时序目标，用来比较 RTL 能否在这些目标周期下收敛。若比赛或验收要求板上真实运行到更高频率，需要加入 PLL/MMCM 或外部高频时钟，并同步修改顶层和 XDC。

## 3. 创建 Vivado 工程

在 Vivado Tcl Console 中执行：

```tcl
set PART_NAME xc7k325tffg900-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
source ../../vivado/create_board_project.tcl
```

参数说明：

- `PART_NAME`：K7EDAEVAL 对应器件。若实际板卡不同，改成你的 Vivado part name。
- `TARGET_PERIOD_NS 20.000`：50 MHz 约束。
- `TARGET_PERIOD_NS 10.526`：95 MHz 时序目标，只改变约束，不改变真实输入时钟。
- `ENABLE_ILA 1`：生成并接入 ILA，用于首次上板观察。
- `ENABLE_ILA 0`：不接 ILA，用于最终资源/时序比较。

综合实现：

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary
report_utilization
```

如果 `WNS < 0`，先不要把该目标频率作为最终结果。可以降低目标频率、换路线，或用 `report_design_analysis -timing` 看关键路径。

## 4. 下载与观察

连接 K7EDAEVAL 后，在 Vivado Hardware Manager 中：

1. Open Target。
2. Program Device。
3. 选择生成的 `.bit` 文件。
4. 如果启用了 ILA，同时加载对应 `.ltx`。

板级 LED 映射：

| 信号 | 含义 |
| --- | --- |
| `LED1` | `done`，程序完成标志。 |
| `LED2` | `verify_we`，输出 RAM 写使能。 |
| `LED3` 到 `LED7` | `cnt_test` 的部分位，用于粗略观察运行状态。 |
| `LED8` | `verify_RAM` debug 数据异或值。 |

当前 ILA probe：

| probe | 信号 |
| --- | --- |
| `probe0` | `test_vector_in[15:0]` |
| `probe1` | `verify_vector_out[15:0]` |
| `probe2` | `verify_we` |
| `probe3` | `verify_addr[4:0]` |
| `probe4` | `cnt_test[19:0]` |
| `probe5` | `done` |

首次上板重点确认：

- `done` 最终拉高。
- `verify_we` 出现 16 次有效写入。
- 最后一次写入地址为 15。
- `cnt_test` 稳定在约 157。
- `verify_vector_out` 写入序列与 `mem/FFT_output.coe` 一致。

## 5. 高频路线比较

在有 Vivado 的机器上运行矩阵：

```powershell
cd routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
```

默认矩阵：

- 路线：v6、v7、v7b、v7c。
- 目标频率：95、100、110、120、130 MHz。
- 策略：`Performance_Explore`、`Performance_ExplorePostRoutePhysOpt`。

输出的 `route_a_matrix.csv` 字段：

| 字段 | 含义 |
| --- | --- |
| `route` | 路线名称。 |
| `target_mhz` | Vivado 目标频率。 |
| `strategy` | Vivado 实现策略。 |
| `wns_ns` | Worst Negative Slack。非负表示该目标周期下时序收敛。 |
| `lut`、`ff`、`dsp`、`bram` | 资源占用。 |
| `status` | 报告解析或 Vivado run 状态。 |
| `notes` | 脚本记录的路线、目标频率、器件等信息。 |

选择规则：先取 `WNS >= 0` 的最高频率；频率相同再比较资源。若常数 91 专用路线没有明显优势，优先保留 `speed_v7_q7_narrow_mul`。

## 6. 异常处理

常见问题和处理建议：

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| 回归脚本提示找不到 `iverilog` | 未安装 Icarus Verilog 或未加入 PATH | 安装工具后重试，或改用 Vivado 仿真/实现。 |
| Vivado 找不到 `clk_50m` 约束 | XDC 中时钟约束被改名 | 检查 `constraints/top.xdc` 中的 `create_clock` 行。 |
| `done` 不拉高 | 复位极性、ROM 初始化或时钟异常 | 先看 `KEY1`、`CLK_50M`、`mem/instr_fft8.mem` 是否正确。 |
| `verify_we` 次数不是 16 | 汇编程序未按预期写完输出 | 用 ILA 看 `verify_addr` 和 `cnt_test`，再回到仿真定位。 |
| 高频 `WNS < 0` | 关键路径超时 | 降频、换实现策略，或比较 v7b/v7c 的专用乘法路线。 |

## 7. 回退路径

如果某条路线在 Vivado 或上板中异常，按下面顺序回退：

1. 回到 `speed_v6_official_sample`，确认官方兼容功能正确。
2. 再切到 `speed_v7_q7_narrow_mul`，确认窄乘法正确。
3. 最后比较 `speed_v7b_c91_shift_add` 与 `speed_v7c_c91_shift_sub` 的时序和资源。

各路线相互独立，不需要覆盖已有可用版本。
