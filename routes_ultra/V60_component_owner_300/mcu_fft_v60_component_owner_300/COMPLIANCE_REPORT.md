# V60 合规性说明

## 1. 结论

V60 仍属于普通 MCU 指令并行计算路线，不是专用 FFT 加速器路线。

| 检查项 | 结论 |
| --- | --- |
| 32-bit ARM-like 普通指令 | 保持 |
| 每个 core 是否完整 MCU | 是 |
| FFT engine | 无 |
| butterfly unit | 无 |
| DMA controller | 无 |
| coprocessor | 无 |
| FFT/复数/蝶形专用 opcode | 无 |
| verify 是否由普通 `STR` 写入 | 是 |
| DSP | 0 |
| 官方样例 + 20 随机 | PASS |

## 2. 为什么不是专用加速器

V60 的速度来自任务拆分，而不是新增硬件算子。16 个 core 的结构相同，均包含 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。每个 core 从自己的指令 ROM 中取 32-bit 指令，按普通 MCU 流水执行。

实际执行的指令类型可在 `results/opcode_summary_all.csv` 中查看，包含：

- `MOVI`
- `LDR`
- `ADD`
- `SUB`
- `MUL`
- `STR`
- `HALT`

没有 `BFY`、`FFT_STAGE`、`BUTTERFLY`、`CMUL`、`CADD`、`CSUB` 等专用指令。

## 3. 数据路径说明

输入数据来自测试 ROM。每个 core 使用普通 `LDR` 指令读取自己需要的实部和虚部输入。计算过程中使用普通 `ADD/SUB/MUL` 指令。计算完成后，每个 core 使用普通 `STR` 指令把自己的结果写到固定 verify 地址。

`verify_RAM_component16` 只保存 verify 写回结果供 LED/ILA/debug 观察，不参与 FFT 计算，也不做加法、乘法、蝶形或 twiddle 运算。

## 4. 计数口径

`cnt_test` 是全系统 wall-clock 计数：

1. 首个有效 FFT 输入读取触发开始计数。
2. 每个 verify 地址对应的 owner core 完成普通 `STR`。
3. 16 个地址均可信写入后，停表信号打一拍进入 `cnt_test_unit`。

因此 `cnt_test=38` 不是通过少写地址、跳过 addr15 或提前停表得到的。仿真证据见 `results/verify_writer_trace.csv`。

## 5. 审计文件

- `results/forbidden_module_scan.txt`
- `results/forbidden_opcode_scan.txt`
- `results/opcode_summary_all.csv`
- `results/octa_audit_summary.txt`
- `results/verify_writer_trace.csv`
- `results/regression_summary.txt`

