# V53 四核合规检查报告

## 检查结论

V53 满足当前约束：四个完整 MCU core 执行普通指令 ROM，未加入 FFT/DFT 专用硬件，未加入专用指令，DSP 使用为 0，verify RAM 由普通 `STR` 写入。

## 指令与架构

| Core | 指令数 | 主要指令 |
| --- | ---: | --- |
| Core0 | 110 | `MOVI/LDR/ADD/SUB/MUL/STR/HALT` |
| Core1 | 118 | `MOVI/NOP/LDR/ADD/SUB/STR/HALT` |
| Core2 | 123 | `MOVI/NOP/LDR/ADD/SUB/STR/HALT` |
| Core3 | 107 | `MOVI/NOP/LDR/ADD/SUB/STR/HALT` |

审计结果：

```text
PASS: no forbidden FFT/DFT/DMA/coprocessor modules found in rtl/*.v
PASS: no forbidden BFY/FFT_STAGE/BUTTERFLY/CMUL/CADD/CSUB opcodes found
```

## 禁止项检查

| 禁止项 | 状态 |
| --- | --- |
| FFT engine | 未发现 |
| butterfly_unit | 未发现 |
| fft_stage_unit | 未发现 |
| twiddle_engine | 未发现 |
| DMA controller | 未发现 |
| coprocessor | 未发现 |
| FFT/复数/蝶形专用 opcode | 未发现 |
| DSP | 0 |
| ILA 计入正式成绩 | 未启用 |

## verify 写回

V53 使用 `done_mask` 判断 16 个 verify 地址全部完成，避免 addr15 提前写入造成假停表。

| cycle | verify_addr | writer |
| ---: | ---: | --- |
| 104 | 3 | Core3 |
| 105 | 11 | Core3 |
| 106 | 7 | Core3 |
| 107 | 15 | Core3 |
| 115 | 1 | Core1 |
| 116 | 9 | Core1 |
| 117 | 5 | Core1 |
| 118 | 13 | Core1 |
| 120 | 2 | Core2 |
| 121 | 10 | Core2 |
| 122 | 6 | Core2 |
| 123 | 0 | Core0 |
| 123 | 14 | Core2 |
| 124 | 8 | Core0 |
| 125 | 4 | Core0 |
| 126 | 12 | Core0 |

最终 `cnt_test=72`，`verify_writes=16`，`done_mask=ffff`。

## 随机数据适配性

本路线不针对官方样例硬编码。回归使用官方样例和 seed=2026 起的 20 组随机输入，全部 PASS。计算仍由普通 MCU 指令在不同输入数据上执行。

