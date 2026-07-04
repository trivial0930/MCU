# V26 路线记录：汇编调度与输出基址前移

## 基线分析

V22b/V26 生成后的 FFT 程序共 162 条指令：

| 指令 | 数量 |
| --- | ---: |
| MOVI | 5 |
| LDR | 48 |
| STR | 48 |
| ADD | 26 |
| SUB | 30 |
| MUL | 4 |
| HALT | 1 |
| CMP/B/BEQ/BNE/BL | 0 |

关键依赖情况：

- `OP_MUL` 共 4 条。
- MUL 后第一次使用目标寄存器的距离分别约为 4、3、5、3 条指令。
- 未发现 `LDR` 后立即使用的 load-use hazard。
- 当前 `mcu_core` 在 `mul_busy` 期间停发，所以单纯在 MUL busy 中穿插指令空间有限。
- 程序已经完全展开，没有循环分支，也没有 HALT 前的无效 NOP。

## 修改内容

只修改 `scripts/gen_fft8_official_asm.py`，并由回归脚本重新生成 `asm/fft8_official_sample.asm` 与 `mem/instr_fft8.*`。

具体调整：

- 将 `MOVI R5, #VERIFY_BASE` 从 Stage 3 前移到 start 初始化区。
- 将 twiddle 计算中原来使用 R5 的临时虚部寄存器改为 R14。
- 不修改 RTL、不修改计数器、不新增专用指令。

## 验证结果

| 项目 | 结果 |
| --- | ---: |
| 官方样例 | PASS |
| 20 组随机 | PASS |
| `cnt_test` | 172 |
| 300 MHz timing | PASS |
| WNS/TNS | +0.067 ns / 0.000 ns |
| WHS/THS | +0.119 ns / 0.000 ns |
| LUT/FF/DSP | 1050 / 675 / 0 |

## 结论

V26 的收益来自减少计数窗口内 1 条初始化指令，不是修改计数逻辑。它可以作为后续最快路线候选，但上板展示仍建议优先保留 V22b 作为已验证基线。
