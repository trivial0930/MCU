# V31 路线记录：单核最终微调

## 来源

V31 从 `routes_ultra/V28_branch_reduce_300/mcu_fft_v28_branch_reduce_300` 复制而来，保持单核 MCU 架构、300 MHz PLL、`flatten_hierarchy=none`、`max_dsp=0` 和无 ILA 统计口径。

## V28/V26 基线统计

| 项目 | V28/V26 |
| --- | ---: |
| 总指令数 | 162 |
| LDR | 48 |
| STR | 48 |
| ADD | 26 |
| SUB | 30 |
| MUL | 4 |
| MOVI | 5 |
| MOVR | 0 |
| NOP | 0 |
| B/BEQ/BNE/BL | 0 |
| HALT | 1 |
| first_test_rom_read | index 5：`LDR R8, [R7 + 128]` |
| last_verify_ram_write | index 160：`STR R3, [R5 + 15]` |

HALT 前最后 10 条：

```text
151 LDR R10, [R0 + 14]
152 LDR R11, [R0 + 15]
153 ADD R12, R8, R10
154 ADD R13, R9, R11
155 SUB R2, R8, R10
156 SUB R3, R9, R11
157 STR R12, [R5 + 3]
158 STR R13, [R5 + 11]
159 STR R2, [R5 + 7]
160 STR R3, [R5 + 15]
```

## 实际修改

修改文件：

- `scripts/gen_fft8_official_asm.py`

优化点：

- 对 W2 蝶形不再先计算 `a.real - b.real` 再取反，而是直接生成 `b.real - a.real`。
- 3 个 W2 蝶形各减少 1 条 `SUB`，counted 窗口减少 3 拍。
- `R1=0` 初始化不再需要，W3 的取反改用已经为 0 的 `R0`；这减少总指令数，但该指令原本在计数窗口外，因此不影响 `cnt_test`。
- 未改变输出写入顺序，未改变 `cnt_test` start/stop 口径，未新增硬件或专用指令。

## V31 指令统计

| 项目 | V31 |
| --- | ---: |
| 总指令数 | 158 |
| LDR | 48 |
| STR | 48 |
| ADD | 26 |
| SUB | 27 |
| MUL | 4 |
| MOVI | 4 |
| MOVR | 0 |
| NOP | 0 |
| B/BEQ/BNE/BL | 0 |
| HALT | 1 |
| first_test_rom_read | index 4：`LDR R8, [R7 + 128]` |
| last_verify_ram_write | index 156：`STR R3, [R5 + 15]` |

HALT 前最后 10 条：

```text
147 LDR R10, [R0 + 14]
148 LDR R11, [R0 + 15]
149 ADD R12, R8, R10
150 ADD R13, R9, R11
151 SUB R2, R8, R10
152 SUB R3, R9, R11
153 STR R12, [R5 + 3]
154 STR R13, [R5 + 11]
155 STR R2, [R5 + 7]
156 STR R3, [R5 + 15]
```

## 验证结果

| 项目 | 结果 |
| --- | ---: |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 169 |
| 300 MHz timing | PASS |
| 理论时间 | 0.563 us |
| WNS/TNS | +0.181 ns / 0.000 ns |
| WHS/THS | +0.101 ns / 0.000 ns |
| LUT/FF/DSP | 1053 / 675 / 0 |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v31_single_core_final_tune_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## 结论

V31 是当前最快的单核 300 MHz timing-clean 路线。它没有新增第二个 core、没有新增 FFT/蝶形/复数专用硬件、没有改 `cnt_test` 口径，建议作为新的单核最终候选；上板前建议按 V22b 的 ILA 方法再做一次实物验证。
