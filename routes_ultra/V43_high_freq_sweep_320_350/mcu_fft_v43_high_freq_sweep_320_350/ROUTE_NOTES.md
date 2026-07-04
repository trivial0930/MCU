# V43 路线记录：高频扫频

## 定位

V43 的目标不是减少 `cnt_test`，而是在 V42/V34 已经实物验证的 88cnt 方案上，测试直接提高 PLL 输出频率是否可行。这样可以把“架构/指令流优化”和“频率上探”分开评估。

## 与 V42 的差异

- `rtl/board_top.v` 中 PLL 参数改为宏可配置，默认仍为 300 MHz。
- 新增 `scripts/run_freq_sweep.py` 自动生成每个频点的 Vivado wrapper Tcl。
- no-ILA 统计路径保持不变，ILA 只属于 V42/V34 的板上验证材料，不进入 V43 官方成绩。

## 扫频点

| 目标频率 | PLL 设置 | 状态说明 |
| --- | --- | --- |
| 300 MHz | `MULT=30, DIV=5` | V42/V34 基线 |
| 320 MHz | `MULT=32, DIV=5` | 合法 VCO，尝试实现 |
| 333.333 MHz | `MULT=20, DIV=3` | 合法 VCO，接近 333 MHz |
| 340 MHz | `MULT=34, DIV=5` | VCO=1700 MHz，预计超出 PLLE2 范围 |
| 350 MHz | `MULT=28, DIV=4` | 合法 VCO，尝试实现 |
| 360 MHz | `MULT=36, DIV=5` | VCO=1800 MHz，预计超出 PLLE2 范围 |

## 判定口径

一个频点只有同时满足以下条件，才计入可展示速度榜：

1. Vivado 生成 bitstream。
2. WNS/TNS、WHS/THS 均满足时序。
3. DSP=0。
4. 本路线的官方样例 + 20 组随机回归 PASS。

最终结论见 `HIGH_FREQ_SWEEP_REPORT.md` 和 `results/freq_sweep.csv`。
