# V60 路线说明

## 1. 来源和优先级

本轮在 V60 到 V65 的候选中，优先选择 V60。原因是 V60 的 real/imag component-owner 拆分不需要跨核合并 partial sum，合规解释最直接，速度收益也最大。

| 路线 | 判断 |
| --- | --- |
| V60 16 核 component-owner | 已完成，已上板，成为当前最快路线 |
| V65 多核 cluster / routing | 暂不单独开线；V60 已 300 MHz timing clean |
| V61 12 核 helper | helper 需要 shared-RAM 同步，预计不如 V60 直接 |
| V62 16 核 partial-sum | 需要 partial-sum 合并，容易引入等待和合规解释成本 |
| V63 16 核 verify/output helper | verify helper 会增加交接，不如 owner core 直接 `STR` 清晰 |
| V64 24/32 核 term-owner | 核数和合并网络过重，routing 和验收解释风险最高 |

## 2. 结构变化

V60 从 `V59_octa_fast_stop_300` 复制而来，主要变化如下：

- `mcu_top.v` 从 8 core 扩展为 16 core。
- `board_top.v` 为 16 个 core 复制测试 ROM 读口。
- 每个 core 有独立指令 ROM：`mem/instr_core0.mem` 到 `mem/instr_core15.mem`。
- 新增 `scripts/gen_fft8_component_asm.py`，根据 `mem/FFT_input.coe` 生成 16 个 component-owner 汇编程序。
- `tb/tb_mcu_fft8.v` 扩展为 16 core trace，记录每个 core 的输入读取和 verify 写回。
- `verify_RAM_component16` 仅用于板上 debug 数据保持；FFT 计算仍完全由各 MCU core 的普通指令完成。

## 3. Core 分工

| Core | 输出分量 | verify 地址 |
| ---: | --- | ---: |
| 0 | `real(X0)` | 0 |
| 1 | `real(X1)` | 1 |
| 2 | `real(X2)` | 2 |
| 3 | `real(X3)` | 3 |
| 4 | `real(X4)` | 4 |
| 5 | `real(X5)` | 5 |
| 6 | `real(X6)` | 6 |
| 7 | `real(X7)` | 7 |
| 8 | `imag(X0)` | 8 |
| 9 | `imag(X1)` | 9 |
| 10 | `imag(X2)` | 10 |
| 11 | `imag(X3)` | 11 |
| 12 | `imag(X4)` | 12 |
| 13 | `imag(X5)` | 13 |
| 14 | `imag(X6)` | 14 |
| 15 | `imag(X7)` | 15 |

## 4. 程序优化

每个 core 只读取自己计算该分量需要的输入对，并通过普通 `ADD/SUB/MUL` 累加。程序生成器还去掉了显式的 `MOVI R12,#0` 和 `MOVI R14,#0`，因为寄存器堆在 reset 时已经清零。这个改动没有改变 `cnt_test`，但把总指令数从 592 降到 560。

最终指令统计：

| 项目 | 结果 |
| --- | ---: |
| 偶数分量 core 指令数 | 33 |
| 奇数分量 core 指令数 | 37 |
| 总指令数 | 560 |
| 禁用 opcode | 0 |
| 禁用模块 | 0 |

## 5. verify 和停表路径

V60 的 `cnt_test` 停在 16 个 verify 地址全部完成之后：

- 偶数地址在 ILA sample 23 写入，写使能掩码 `0x5555`。
- 奇数地址在 ILA sample 31 写入，写使能掩码 `0xaaaa`。
- addr15 与最后一批写入同周期出现。
- `fast_stop_pulse_dbg` 在 sample 32 触发。
- `verify_done_mask_q=ffff`，`verify_done_mask_next=ffff`。
- `done` 在 sample 33 变为 1，稳定 `cnt_test=38`。

证明文件见 `board_validation/v60_fast_stop_proof.csv` 和 `board_validation/v60_hw_compare_status.txt`。

## 6. Vivado 结果

正式 no-ILA 版本：

| 项目 | 结果 |
| --- | ---: |
| 频率 | 300 MHz |
| WNS | +0.014 ns |
| TNS | 0.000 ns |
| WHS | +0.064 ns |
| THS | 0.000 ns |
| LUT | 16970 |
| FF | 13203 |
| DSP | 0 |
| BRAM | 0 |
| DRC | 0 checks found |

ILA 证明版：

| 项目 | 结果 |
| --- | ---: |
| 频率 | 300 MHz |
| WNS | +0.007 ns |
| TNS | 0.000 ns |
| WHS | +0.013 ns |
| THS | 0.000 ns |
| LUT | 19126 |
| FF | 17060 |
| DSP | 0 |
| BRAM | 12 |
| DRC | 只有 dbg_hub/ILA 相关 warning，无 error |

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
```

## 7. 当前建议

V60 建议作为新的最快主线。验收展示时使用无 ILA bitstream 进行正式测速，必要时切换到 ILA 证明版展示 fast-stop 未提前：16 个 verify 地址已经全部写入，且 `verify_done_mask_q/next` 均为 `0xffff` 后才停表。
