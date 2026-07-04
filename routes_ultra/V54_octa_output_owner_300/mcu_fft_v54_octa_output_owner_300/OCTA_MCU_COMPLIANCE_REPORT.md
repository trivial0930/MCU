# V54 八核 MCU 合规报告

## 结论

V54 是 8 个完整 MCU core 的输出归属拆分路线，不是 FFT 专用硬件加速器。所有输出均由普通 32-bit ARM-like 指令序列计算，并由普通 `STR` 指令写入 verify RAM。当前版本已经完成 300MHz no-ILA timing-clean 实现和实物上板验证。

## 禁项检查

| 禁项 | V54 状态 |
| --- | --- |
| FFT engine | 未新增 |
| butterfly_unit / fft_stage_unit | 未新增 |
| twiddle_engine | 未新增 |
| DMA controller | 未新增 |
| coprocessor | 未新增 |
| BFY / FFT_STAGE / BUTTERFLY 指令 | 未新增 |
| CMUL / CADD / CSUB 专用复数指令 | 未新增 |
| 固定硬件蝶形网络 | 未新增 |
| shared RAM 参与计算 | 未使用 shared RAM 计算 |

## MCU 完整性

Core0..Core7 都实例化同一套 `mcu_core`：

- PC / instruction address
- instruction ROM
- decoder
- control unit
- register file
- ALU / ordinary MUL
- load-store interface
- writeback
- halt / done

每个 core 的程序来自独立指令 ROM 文件：

```text
mem/instr_fft8.mem
mem/instr_core1.mem
mem/instr_core2.mem
mem/instr_core3.mem
mem/instr_core4.mem
mem/instr_core5.mem
mem/instr_core6.mem
mem/instr_core7.mem
```

## 指令使用情况

V54 使用的 opcode 只有：

```text
MOVI, MOVR, LDR, ADD, SUB, MUL, STR, HALT
```

其中：

- `LDR` 用于从复制后的 test ROM 读取输入。
- `ADD/SUB/MUL` 用于普通整数定点计算。
- `STR` 用于写入 verify RAM。
- `HALT` 用于 core 完成后停止。

详细统计见 `results/opcode_summary_all.csv`。

## verify 写回可信性

仿真和板上记录显示：

- verify 写回次数：16
- 覆盖地址：0..15
- 最后写回地址：15
- `done_mask=ffff`
- 官方样例和 20 组随机全部 PASS
- 板上 ILA 输出比对 PASS

当前停表不是依赖某一个 verify 地址提前写入，而是每个 owner core 都完成两次 verify 写回后再打一拍停止。这个改动让 `cnt_test=59`，比旧的 58 多 1 个保守周期，但提高了 300MHz WNS，并避免假停表风险。

## Vivado 结果

| 项目 | 正式 no-ILA | ILA 调试版 |
| --- | ---: | ---: |
| 频率 | 300 MHz | 300 MHz |
| WNS/TNS | +0.095 / 0.000 ns | +0.072 / 0.000 ns |
| WHS/THS | +0.072 / 0.000 ns | +0.044 / 0.000 ns |
| LUT/FF | 8733 / 6476 | 10325 / 9383 |
| DSP | 0 | 0 |
| BRAM | 0 | 6 |
| DRC | Checks found: 0 | Checks found: 0 |

正式 bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
```

ILA 调试 bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
```
