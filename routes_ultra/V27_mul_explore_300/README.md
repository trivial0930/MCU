# V27_mul_explore_300

V27 探索更激进的通用 Q7 `OP_MUL` 优化，分为两个独立子实验：

- `V27a_mul1_lut_300`：单拍通用 LUT 移位加法树乘法。
- `V27b_hybrid_mul_300`：通用 small-constant fast path，其他乘数保留慢路径。

两条路线都保持 DSP=0，官方样例和 20 组随机均 PASS，但 300 MHz 时序均不收敛，因此不能替代 V22b/V26/V28。

| 路线 | 回归 | `cnt_test` | 300 MHz WNS | LUT | FF | DSP | 结论 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| V22b baseline | PASS | 173 | +0.122 ns | 1053 | 675 | 0 | 已上板验证基线 |
| V27a_mul1_lut_300 | PASS | 157 | -2.199 ns | 1203 | 648 | 0 | 功能成功，时序失败 |
| V27b_hybrid_mul_300 | PASS | 157 | -1.052 ns | 1361 | 698 | 0 | 功能成功，时序失败 |

结论：在当前 K7 `xc7k160tffg676-2`、300 MHz、`max_dsp=0` 条件下，单拍 25-bit x 8-bit Q7 乘法路径过长。V27b 切断 MUL EX 前递后 WNS 从约 -1.49 ns 改善到 -1.052 ns，但单拍常数 91 写回路径仍有 16 级逻辑，无法收敛。
