# V27b 路线记录：hybrid 通用 Q7 MUL

## 目标

在不新增专用指令的前提下，给通用 `OP_MUL` 增加 small-constant fast path，尝试把 FFT 程序中的乘法周期压低到接近单拍。

## 实现方式

- fast path 覆盖 0、1、2、4、8、16、32、64、91、128 等通用常数。
- 非 fast path 继续走 V22b 的两拍通用移位累加器。
- 为避免 EX 前递形成过长组合回路，MUL 结果不参与 EX forwarding；若下一条指令紧邻使用 MUL 结果，由 RAW hazard 等待 WB 前递。

## 验证

| 项目 | 结果 |
| --- | ---: |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 157 |
| WNS/TNS | -1.052 ns / -99.143 ns |
| LUT/FF/DSP | 1361 / 698 / 0 |

## 结论

功能正确，但 300 MHz 不通过。该路线保留为负结果和后续参考；如果要继续推进，需要把常数乘法写回再流水化，但那会牺牲一部分 `cnt_test` 收益。
