# V24_load_forward_300

V24 基于当前最快单核路线 V22b，尝试加入 `LDR` 的安全前递，验证 load-use forwarding 对本 FFT 汇编是否还有速度收益。

## 修改内容

- 源路线：`V22b_fast_mul2_300`。
- 只修改 `rtl/mcu_core.v`。
- 新增独立的 `load_forward_*` 信号。
- 只允许 `test_ROM` 区域的 `LDR` 在 EX 阶段前递。
- `data_ram` 区域的 `LDR` 仍然保持保守 stall，避免把 RAM 读路径压入更深的 operand mux。
- 保留 V22b 的 2 拍通用 Q7 `OP_MUL`，不新增 FFT/蝶形/复数乘法专用指令。
- 保持 `max_dsp=0`。

## 预期风险

当前 `fft8_official_sample.asm` 中没有紧邻的 `LDR -> use` 指令对，因此 V24 可能不会降低 `cnt_test`。本路线的价值主要是实测确认 load forwarding 是否值得继续和后续路线合并。

## 验证结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 173 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.577 us |
| WNS | -0.005 ns |
| TNS | -0.005 ns |
| WHS | +0.096 ns |
| THS | 0.000 ns |
| LUT | 1106 |
| FF | 681 |
| DSP | 0 |

## 结论

V24 不建议作为主线合并或上板。原因如下：

- 当前汇编没有紧邻 `LDR -> use` hazard，新增 test_ROM load forwarding 没有降低 `cnt_test`。
- 额外 operand mux 和判断逻辑让资源从 V22b 的 1053 LUT / 675 FF 增加到 1106 LUT / 681 FF。
- 300 MHz post-route WNS 从 V22b 的 `+0.122 ns` 变为 `-0.005 ns`，不满足正式 timing-clean 口径。

因此 V24 的有效结论是：在现有 V22b 汇编调度下，load-use forwarding 不是优先优化方向。后续应继续保留 V22b 作为最快单核主线，除非未来汇编调度产生大量紧邻 LDR-use，再重新评估该机制。
