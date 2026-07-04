# V21_forward_stable_300

V21 基于 V20，目标是保持 `cnt_test=197` 的速度，同时改善 V20 只有 `+0.004 ns` 的极薄时序余量。

## 修改内容

- 只修改 `rtl/mcu_core.v`。
- 将 EX forwarding 的公共 `valid/waddr` 判断拆成 `rs1/rs2` 局部命中信号。
- 将 `raw_hazard_ex` 拆成 `raw_hazard_ex_rs1/raw_hazard_ex_rs2`，减少公共组合扇出。
- 不改变指令集、不新增 FFT/蝶形/协处理器/DMA。
- 保持 `max_dsp=0`。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 197 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.657 us |
| WNS | +0.031 ns |
| TNS | 0.000 ns |
| WHS | +0.133 ns |
| THS | 0.000 ns |
| LUT | 973 |
| FF | 675 |
| DSP | 0 |
| BRAM | 0 |

## 结论

V21 相比 V20 速度不变，但 WNS 从 `+0.004 ns` 提升到 `+0.031 ns`，资源也略低。它可以替代 V20 作为 forward 路线基线，但已经被 V22/V22b 的通用 MUL 加速路线超过。
