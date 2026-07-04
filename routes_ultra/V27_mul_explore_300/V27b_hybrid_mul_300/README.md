# V27b_hybrid_mul_300

V27b 探索通用 small-constant fast path：当 multiplier 是 0、1、2 的幂或 91 等常数时走快速移位加法路径，其他乘数保留 V22b 的两拍通用路径。

注意：91 被放在 `mul_const_fast` 通用常数集合中，未新增 `MUL91`、twiddle、FFT 或复数专用指令。

## 修改内容

- 修改 `rtl/mcu_core.v`。
- 新增 `mul_const_fast` 判定与通用常数移位加法路径。
- 保留 V22b 的 slow MUL 路径作为 fallback。
- 切断 MUL EX 前递，避免乘法结果组合路径直接回到下一条指令操作数。
- DSP 保持 0。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 157 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.523 us |
| WNS | -1.052 ns |
| TNS | -99.143 ns |
| WHS | +0.098 ns |
| THS | 0.000 ns |
| LUT | 1361 |
| FF | 698 |
| DSP | 0 |

## 结论

V27b 比 V27a 的时序更接近收敛，但仍未达到 300 MHz。它证明常数快路径能显著降低周期数，但当前单拍 91 常数乘法写回路径仍过长，不建议作为主线。
