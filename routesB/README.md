# 路线 B 方案目录

本目录集中保存路线 B 的 4 个候选实现。路线 B 的目标不是改变题目输入输出格式，而是在“仍由 MCU 指令驱动 FFT”的前提下，减少 `cnt_test` 或给出更好的速度/效率折中。

注意：目录名按当前任务要求使用 `routesB`。后续脚本和文档都沿用这个拼写，避免路径不一致。

## 方案划分

| 方案 | 工程目录 | 核心思路 | 预期收益 | 风险 |
| --- | --- | --- | --- | --- |
| B1 | `B1_full_fusion/mcu_fft_b1_full_fusion` | 全融合 W1/W3 中的 `ADD/SUB + MUL91`，使用 `MADD91`、`MSUB91`、`MNSUM91` 三条 NOP 扩展指令。 | 周期最低，当前可把 `cnt_test` 降到约 151。 | ALU 组合路径最长，130 MHz 曾未收敛。 |
| B2 | `B2_w1_only_fusion/mcu_fft_b2_w1_only_fusion` | 只融合 W1 蝶形中的两次常数乘，W3 保持普通指令序列。 | 比 B1 保守，减少部分周期。 | 周期收益低于 B1。 |
| B3 | `B3_w3_only_fusion/mcu_fft_b3_w3_only_fusion` | 只融合 W3 蝶形中更长的常数乘序列，W1 保持普通指令序列。 | 在收益和时序压力之间折中，理论上比 B2 多省 1 个周期。 | 仍会引入复合常数乘路径。 |
| B4 | `B4_schedule_only/mcu_fft_b4_schedule_only` | 不改指令集，只把 `VERIFY_BASE` 初始化提前到首个测试 ROM 读取之前。 | 最稳妥，理论上继承路线 A 的时序优势，并少计 1 个 `cnt_test` 周期。 | 周期收益最小。 |

## 快速回归

在仓库根目录执行：

```powershell
$env:PATH = "C:\iverilog\bin;$env:PATH"
py routesB\scripts\run_routesB_regressions.py --random-cases 20 --seed 2026
```

每个方案会生成：

- `asm/fft8_official_sample.asm`：由该方案生成器输出的 FFT 程序。
- `mem/instr_fft8.mem` / `mem/instr_fft8.coe`：对应指令 ROM。
- `results/verify_output.txt`：官方样例输出。
- `results/regression_summary.txt`：官方样例和随机回归结果。
- `results/routesB_regression.log`：完整运行日志。

## 当前功能回归结果

本轮已在本机使用 Icarus Verilog 跑通官方样例和 20 组随机输入，随机种子范围为 `2026` 到 `2045`。

| 方案 | 指令数 | `cnt_test` | 官方样例 | 20 组随机回归 | 当前判断 |
| --- | ---: | ---: | --- | --- | --- |
| B1 | 156 | 151 | PASS | PASS | 周期最低，但 Vivado 130 MHz 仍需继续做时序优化。 |
| B2 | 160 | 154 | PASS | PASS | 只融合 W1，收益较小但预计时序压力低于 B1。 |
| B3 | 159 | 153 | PASS | PASS | 只融合 W3，是目前最值得继续综合对比的折中方案。 |
| B4 | 162 | 156 | PASS | PASS | 不改指令集，最适合作为低风险上板备选。 |

机器可读汇总见 `results/route_b_summary.csv`。

## Vivado 速度/效率矩阵

路线 B 已补齐统一 Vivado 矩阵脚本，用来在同一个器件、同一套综合设置下比较 B1 到 B4。

默认配置：

- 目标器件：`xc7k160tffg676-2`
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 默认频点：95、100、110、120、130 MHz
- 输出目录：`routesB/build/vivado_matrix`

运行方式：

```powershell
cd routesB
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_routesB_matrix.tcl
py scripts\parse_vivado_reports.py --root build\vivado_matrix --out results\route_b_matrix.csv
py scripts\make_leaderboards.py --in-csv results\route_b_matrix.csv --summary-csv results\route_b_summary.csv --out-dir results
```

如果 Vivado 安装路径不同，把第一行命令中的 `D:\vivado\2025.2\Vivado\bin\vivado.bat` 替换成本机实际路径即可。脚本会为每个候选方案和频点生成 post-route timing、utilization、hierarchical utilization、DRC、methodology 和 design analysis 报告。解析后会得到：

- `results/route_b_matrix.csv`：每个方案/频点的 WNS、资源、DSP、BRAM 和实现状态。
- `results/route_b_speed_leaderboard.csv`：按可通过最高频率排序。
- `results/route_b_time_leaderboard.csv`：按 `cnt_test / Fmax` 的真实计算时间排序。
- `results/route_b_efficiency_leaderboard.csv`：按资源效率排序，便于和路线 A 对比。

判断时不要只看 `cnt_test`。路线 B 的最终排名应同时满足功能回归通过、post-route WNS 非负、DSP 为 0，并优先比较 `cnt_test / Fmax`。

## 单方案 bitstream

当某个方案在矩阵中表现较好时，可以进入该方案工程目录生成上板 bitstream：

```powershell
cd routesB\B4_schedule_only\mcu_fft_b4_schedule_only
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_board_bitstream.tcl
```

推荐顺序仍然是 B4、B3、B2、B1：先确认低风险方案能在目标板卡上稳定工作，再尝试收益更高但关键路径更长的融合方案。首次上板建议打开 ILA；用于最终资源和效率统计时应关闭 ILA，避免调试核影响时序和资源结论。

## 上板优先级

建议先保留 B4 作为低风险备选，再用 B3、B2、B1 依次尝试 Vivado。B1 当前周期最好，但此前 130 MHz post-route WNS 为负；B3/B2 可能在周期略高的情况下换来更好的时序。若后续需要正式上板，优先比较 `总时间 = cnt_test / Fmax`，不要只看 `cnt_test`。
