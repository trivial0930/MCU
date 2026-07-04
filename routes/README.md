# 路线 A 工作记录

`routes/` 目录把每条实验路线放在独立文件夹中。这样做的目的很简单：已经通过功能验证的版本不要被后续高频实验破坏，失败的优化也可以直接丢弃或回退。

顶层 `Baseline/` 目录已经删除，避免和 `speed_v5_main_freeze` 重复。原始 baseline 代码和说明统一保留在 `speed_v5_main_freeze/`，路线差异看每个路线目录旁的 `ROUTE_NOTES.md`。

## 路线总览

后续 Vivado 操作、bitstream、ILA 和上板验收步骤见
`../docs/上板与交接指南.md`。

| 路线 | 目标 | 当前检查状态 | 适用场景 |
| --- | --- | --- | --- |
| `speed_v5_main_freeze/` | 从 GitHub `main` 冻结出来的原始 baseline，使用 16 word 交错测试格式和 Q15 乘法。 | 既有记录：baseline 自检 PASS，`cnt_test=224`；KEY1 约束已修正为 `LVCMOS18`。 | 回看原始实现。 |
| `speed_v6_official_sample/` | 兼容 2026 官方 FFT 样例：256 word 测试 ROM、官方地址 128-143、Q5 到 Q12 读入转换、Q7 乘法、DIF 流程修正、官方 real-then-imag 输出布局。 | 既有记录：官方样例 PASS，20 组随机定点回归 PASS，162 条指令，`cnt_test=157`。 | 功能正确性的基准线。 |
| `speed_v7_q7_narrow_mul/` | 路线 A1：保持 v6 行为，把 ALU Q7 乘法收窄为 data x 8-bit coefficient。 | 既有记录：官方样例 PASS，20 组随机回归 PASS，`cnt_test=157`。 | 推荐第一个上板版本。 |
| `speed_v7b_c91_shift_add/` | 路线 A2 备选：把 FFT 程序用到的常数 91 乘法专门化为 `64 + 16 + 8 + 2 + 1` 移位加。 | 既有记录：官方样例 PASS，20 组随机回归 PASS，`cnt_test=157`。 | 比较 LUT/时序时使用。 |
| `speed_v7c_c91_shift_sub/` | 路线 A2 备选：把常数 91 写成 `128 - 32 - 4 - 1` 移位减。 | 既有记录：官方样例 PASS，20 组随机回归 PASS，`cnt_test=157`。 | 比较 LUT/时序时使用。 |
| `speed_v8_high_freq_sweep/` | 路线 A3/A4：基于 v7 窄乘法 RTL 的单路线高频 sweep。 | Vivado 脚本默认 part 已更新为 `xc7k160tffg676-2`，并默认 `flatten_hierarchy=none`、`max_dsp=0`。 | 只看推荐路线的频率边界。 |
| `speed_v8_route_a_vivado_matrix/` | 路线 A3/A4：对 v6、v7、v7b、v7c 做目标频率和 Vivado strategy 矩阵比较。 | 已用 Vivado 2025.2 完成前期综合冒烟；最终首板路线已优先收敛到 `speed_v7_q7_narrow_mul`。 | 决定最终速度路线。 |

## 本机调试结论

当前 Windows 环境可用 `py`、`iverilog`、`vvp` 和 Vivado 2025.2。Vivado 位于：

```text
D:\vivado\2025.2\Vivado\bin\vivado.bat
```

目标器件和 license 已可用。根据 `materials/source_docs/Lab1.pdf` 中的实物封装说明，当前上板 part 使用 `xc7k160tffg676-2`。

推荐首板路线 `speed_v7_q7_narrow_mul` 已完成：

- 综合：PASS
- 实现：PASS
- DRC：0 Error
- bitstream：PASS
- ILA 调试文件：已生成 `.bit` 和 `.ltx`
- 资源统计口径：`flatten_hierarchy=none`，`max_dsp=0`，最新报告 `DSPs=0`

## 重新跑本地功能回归

在安装 Icarus Verilog 后，从仓库根目录执行：

```powershell
py routes\scripts\run_route_a_local_regressions.py --random-cases 20 --seed 2026
```

单独检查某一条路线时，进入路线工程根目录，例如：

```powershell
cd routes\speed_v7_q7_narrow_mul\mcu_fft_q7_narrow_mul
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

脚本会完成以下步骤：

1. 生成官方样例兼容汇编 `asm/fft8_official_sample.asm`。
2. 用 Python 参考模型生成 `mem/FFT_input.mem` 与 `results/expected_fft_output.txt`。
3. 汇编指令 ROM 到 `mem/instr_fft8.mem/.coe`。
4. 用 Icarus Verilog 编译并运行 testbench。
5. 检查官方样例和随机样例输出。

## Vivado 矩阵运行

```powershell
cd routes\speed_v8_route_a_vivado_matrix
vivado -mode batch -source vivado\run_route_a_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_a_matrix.csv
py scripts\make_leaderboards.py --in-csv results\route_a_matrix.csv
```

矩阵默认比较：

- 目标频率：95、100、110、120、130 MHz。
- 实现策略：默认使用已稳定完成报告生成的 `Performance_Explore`。
- 器件：`xc7k160tffg676-2`。
- 综合设置：`flatten_hierarchy=none`，`max_dsp=0`。

如果板卡或 Vivado 工程使用不同器件，可在 Vivado Tcl 中先设置：

```tcl
set PART_NAME <your-part-name>
set JOBS 8
source vivado/run_route_a_matrix.tcl
```

## 最终路线选择规则

1. 先筛选 `WNS >= 0` 的结果。
2. 在能收敛的组合中选目标频率最高者。
3. 若频率相同，优先选择资源更低、结构更通用的路线。
4. 最终提交成绩时不要把 ILA 资源算入比较结果。
5. 如果常数 91 专用路线的时序优势不明显，优先保留 `speed_v7_q7_narrow_mul`，因为它的语义更通用、风险更低。

最新榜单已经生成在 `speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`。早期 synth-only 冒烟 CSV 已移除，避免和正式 post-route、`max_dsp=0` 结果混淆。
