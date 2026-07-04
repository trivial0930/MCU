# V22b_fast_mul2_300

V22b 基于 V22a 继续激进优化通用 Q7 `OP_MUL`，每拍处理 4 bit multiplier，使 8 bit multiplier 约 2 拍完成。

## 修改内容

- 只修改 `rtl/mcu_core.v`。
- `MUL` 仍然是 MCU 通用 Q7 乘法指令。
- 不新增 FFT/蝶形/复数乘法专用指令。
- 不新增协处理器、DMA 或外部 engine。
- 每拍按 `mul_multiplier[3:0]` 组合累加 `1x/2x/4x/8x` multiplicand。
- multiplicand 每拍左移 4，multiplier 每拍右移 4。
- 保持 `max_dsp=0`，Vivado 报告 DSP=0。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 173 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.577 us |
| WNS | +0.122 ns |
| TNS | 0.000 ns |
| WHS | +0.086 ns |
| THS | 0.000 ns |
| LUT | 1053 |
| FF | 675 |
| DSP | 0 |
| BRAM | 0 |

## 上板验证

V22b 已完成实物上板验证。使用带 ILA 调试版本触发 `verify_we=1` 后按 `KEY1` 复位重跑，捕获到 16 次输出写回，地址 0 到 15 全覆盖，写回数据全部匹配 `mem/FFT_output.coe`。最终 `done=1`，`cnt_test=173`。

详细记录见 `board_validation/BOARD_VALIDATION.md`。

## 结论

V22b 是当前 `routes_ultra` 中最快且已上板验证的 300 MHz 路线。相比 V20，`cnt_test` 从 197 降到 173，按 300 MHz 推算从 `0.657 us` 降到 `0.577 us`；同时 WNS 从 `+0.004 ns` 提升到 `+0.122 ns`。
