# 路线 A 上板指南

本文面向 `routes/` 下的路线 A 候选版本：

- `speed_v6_official_sample/mcu_fft_official_sample`
- `speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul`
- `speed_v7b_c91_shift_add/mcu_fft_c91_shift_add`
- `speed_v7c_c91_shift_sub/mcu_fft_c91_shift_sub`

推荐先用 `speed_v7_q7_narrow_mul` 上板做正确性验证；它保持通用 Q7 乘法语义，比常数 91 专用路线更稳。最终速度版本应以 Vivado post-route 的 `WNS`、`LUT`、`FF`、`DSP`、`BRAM` 数据决定。

## 1. 上板前确认

在候选路线目录中先跑一次本地仿真：

```sh
python3 scripts/run_official_regression.py --random-cases 20 --seed 2026
```

确认输出包含：

```text
official_sample PASS
random_seed_2045 PASS
```

该命令会同时生成或刷新上板需要的初始化文件：

- `mem/FFT_input.mem`
- `mem/instr_fft8.mem`
- `mem/instr_fft8.coe`

## 2. 时钟边界

当前 `rtl/board_top.v` 直接使用板载 `CLK_50M`：

```verilog
assign clk = CLK_50M;
```

因此，直接下载 bitstream 时实际运行频率是板载 50 MHz。路线 A 中的 95/100/110/120/130 MHz 脚本是实现时序目标，用来判断 RTL 是否能在该频率下收敛。

如果答辩或比赛要求板上真实运行 95 MHz 以上，需要额外加入 PLL/MMCM 或使用外部高频时钟，并同步更新约束与 `board_top.v`。当前提交没有把 PLL/MMCM 固化进路线代码，避免引入板卡/课程环境不确定的 IP 依赖。

## 3. 生成 Vivado 工程

从候选路线工程根目录运行。例如使用窄乘法路线：

```sh
cd routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
```

在 Vivado Tcl Console 中执行：

```tcl
set PART_NAME xc7k325tffg900-2
set TARGET_PERIOD_NS 20.000
set ENABLE_ILA 1
source ../../vivado/create_board_project.tcl
```

说明：

- `TARGET_PERIOD_NS 20.000` 对应 50 MHz 板载时钟。
- `TARGET_PERIOD_NS 10.526` 对应 95 MHz 时序目标，但不改变板上真实输入时钟。
- `ENABLE_ILA 1` 会把 ILA 加入工程，便于首次上板观察。
- 最终提交速度版本建议设为 `ENABLE_ILA 0`，避免 ILA 资源影响结果。

生成工程后运行：

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary
report_utilization
```

若 `WNS < 0`，先不要上板测速；切换路线或降低目标频率。

## 4. 下载与观察

连接 K7EDAEVAL 后，在 Vivado Hardware Manager 中：

1. Open Target。
2. Program Device。
3. 选择生成的 `.bit` 文件。
4. 如果启用 ILA，同时加载对应 `.ltx`。

当前板级信号：

- `LED1`: `done`
- `LED2`: `verify_we`
- `LED3` 到 `LED7`: `cnt_test` 的部分位
- `LED8`: `verify_RAM` debug 数据异或

当前 ILA 封装可观察：

- `test_vector_in`
- `verify_vector_out`
- `verify_we`
- `verify_addr`
- `cnt_test`
- `done`

建议首次上板时重点确认：

- `done` 最终拉高。
- `verify_we` 出现 16 次有效写入。
- 最后一次写入地址为 `15`。
- `cnt_test` 稳定在约 `157`。
- `verify_vector_out` 写入序列与 `mem/FFT_output.coe` 一致。

## 5. 路线 A 高频比较

在有 Vivado 的机器上运行矩阵脚本：

```sh
cd routes/speed_v8_route_a_vivado_matrix
```

Vivado Tcl Console：

```tcl
set PART_NAME xc7k325tffg900-2
source vivado/run_route_a_matrix.tcl
```

解析报告：

```sh
python3 scripts/parse_vivado_reports.py --root build/vivado_matrix --out results/route_a_matrix.csv
```

比较规则：

- 先筛选 `WNS >= 0` 的版本。
- 再比较 `cnt_test / 实际工作频率`。
- 若速度接近，再看 `6 * LUT + 10 * FF` 和 `DSP/BRAM`。
- 不把带 ILA 的资源计入最终成绩。

## 6. 回退策略

如果某条路线在 Vivado 或上板时异常：

1. 回到 `speed_v6_official_sample` 验证官方兼容正确性。
2. 再切到 `speed_v7_q7_narrow_mul` 验证窄乘法。
3. 最后比较 `speed_v7b_c91_shift_add` 和 `speed_v7c_c91_shift_sub`。

所有路线互相独立，不需要覆盖已有可用版本。
