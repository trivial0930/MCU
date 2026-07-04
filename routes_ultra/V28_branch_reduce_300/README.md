# V28_branch_reduce_300

V28 基于 V22b 检查 branch、HALT 和输出阶段控制开销。当前程序已经完全展开，没有分支或循环，因此真正可删除的控制开销只有 Stage 3 前的 verify_RAM 基址初始化。

## 分析结论

- 无 `B/BEQ/BNE/BL/CMP` 指令。
- 无循环结构。
- HALT 位于最后一次 verify 写入之后，不影响 `cnt_test`。
- `first_test_rom_read` 对应第一次读取输入样本，`last_verify_ram_write` 对应最后一次输出写回，计数口径保持不变。
- 输出 16 次 `STR` 必须由 MCU 普通指令完成，不能用硬件自动输出。

## 修改内容

- 将 `MOVI R5, #VERIFY_BASE` 前移到第一次输入读取之前。
- 将原本使用 R5 的临时虚部寄存器改为 R14。
- 不修改 RTL，不修改 `cnt_test`，不新增专用指令。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 172 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.573 us |
| WNS | +0.067 ns |
| TNS | 0.000 ns |
| WHS | +0.119 ns |
| THS | 0.000 ns |
| LUT | 1050 |
| FF | 675 |
| DSP | 0 |

## 结论

V28 与 V26 的硬件结果一致，属于低风险、低收益优化。它可以作为“V22b 之后的最快 timing-clean 候选”，但还没有替代 V22b 的上板验证地位。
