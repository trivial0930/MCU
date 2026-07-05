# V59 合规说明

V59 是八个完整 MCU core 的 output-owner 路线，不是 FFT 专用硬件加速器。

## 禁止项检查

| 禁止项 | V59 状态 |
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

Core0..Core7 都实例化同一套 `mcu_core`，包含 PC、指令 ROM、decoder、寄存器堆、ALU、普通 MUL、load/store、writeback 和 halt。每个输出值都由对应 core 的普通指令程序计算。

## 指令和写回

V59 使用的 opcode 为：

```text
MOVI, LDR, ADD, SUB, MUL, STR, HALT
```

- `LDR` 从复制后的 test ROM 读取输入数据。
- `ADD/SUB/MUL` 执行普通整数定点计算。
- `STR` 写入 verify RAM。
- verify 写回次数为 16，覆盖地址 0..15。
- 最后一次写回为 Core7 写 addr15。

## 停表口径

V59 的 `cnt_test=49` 来自同拍 owner-complete 停表。停表条件不是某一个地址提前写入，而是 8 个 owner core 都已经发出第二次 verify `STR` 写回。仿真写回轨迹证明 verify 写回次数为 16，最后地址为 15，官方样例和 20 组随机均 PASS。

## Vivado

| 项目 | 结果 |
| --- | --- |
| 频率 | 300 MHz |
| WNS/TNS | +0.095 / 0.000 ns |
| WHS/THS | +0.074 / 0.000 ns |
| LUT/FF | 8677 / 6451 |
| DSP/BRAM | 0 / 0 |
| DRC | Checks found: 0 |
