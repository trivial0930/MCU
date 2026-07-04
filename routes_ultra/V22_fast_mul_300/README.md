# V22_fast_mul_300

V22a 基于 V21，将 MCU 内部普通 `OP_MUL` 的 Q7 乘法从逐 bit 顺序移加改为 radix-4，每拍处理 2 bit multiplier。

## 修改内容

- 只修改 `rtl/mcu_core.v`。
- `MUL` 仍然是 MCU 的通用指令，不新增 FFT/蝶形/复数专用指令。
- 不新增协处理器、DMA 或 start/busy/done 外设。
- 每拍根据 `mul_multiplier[1:0]` 累加 `0x/1x/2x/3x` multiplicand。
- multiplicand 每拍左移 2，multiplier 每拍右移 2。
- 8 bit multiplier 约 4 拍完成。
- 保持 `max_dsp=0`，Vivado 报告 DSP=0。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 181 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.603 us |
| WNS | +0.089 ns |
| TNS | 0.000 ns |
| WHS | +0.074 ns |
| THS | 0.000 ns |
| LUT | 1012 |
| FF | 675 |
| DSP | 0 |
| BRAM | 0 |

## 结论

V22a 明显降低了 `mul_busy` 带来的周期损失，`cnt_test` 从 V21/V20 的 197 降到 181，且 300 MHz WNS 达到 `+0.089 ns`。这是一个稳健的通用 MCU 优化路线。
