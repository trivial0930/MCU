# V40：V34/V38 合规与上板报告材料

## 结论

V34 是当前最快已上板路线，V38 是当前最快 no-ILA 实现路线。两者都保持课程要求的普通 MCU 指令驱动边界，没有引入专用 FFT 硬件。

| 路线 | 状态 | `cnt_test` | WNS | 上板 |
| --- | --- | ---: | ---: | --- |
| V38 | 官方样例 + 20 随机 PASS，300 MHz timing clean | 85 | +0.091 ns | 未上板 |
| V34 | 官方样例 + 20 随机 PASS，300 MHz timing clean | 88 | +0.056 ns | 已上板验证 |

## 已验证事实

V34 上板验证已经完成：

- 硬件识别到 `xc7k160t_0`。
- no-ILA bitstream 可下载。
- ILA 版本可抓到 verify 写回。
- 板上共 16 次 `verify_we`。
- verify 地址覆盖 0 到 15。
- addr15 是最后一次 verify 写。
- 所有 `verify_vector_out` 与 `FFT_output.coe` 匹配。
- addr15 写入时 `cnt_test=87`，最终 `cnt_test=88`。
- 验证后已重新下载 no-ILA 正式 bitstream。

V38 已完成实现验证：

- 官方样例 + 20 组随机输入 PASS。
- `cnt_test=85`。
- no-ILA 300 MHz timing clean。
- DRC 0 Error。
- DSP 0。

## 合规说明

V34/V38 的优化点是双 MCU 调度，不是专用 FFT 加速器：

- Core0 和 Core1 都是完整 MCU。
- 两个 core 都从普通指令 ROM 取 32-bit 指令。
- Core1 指令流包含 `LDR/ADD/SUB/MUL/STR/NOP/HALT` 等普通指令。
- shared RAM 只提供普通数据存储，不做计算。
- verify RAM 由普通 `STR` 指令写入。
- 没有 `BFY`、`FFT_STAGE`、`CMUL`、`CADD`、`CSUB` 等专用指令。
- 没有 FFT engine、butterfly unit、DMA、coprocessor。
- Vivado 使用 `max_dsp=0`，综合实现结果 DSP 为 0。

## 建议展示顺序

1. 先展示 V34：因为它已经上板，风险最低。
2. 再展示 V38：说明这是最新实现成绩，`cnt_test=85`，下一步待上板。
3. 展示 `results/sweep_stage2_wait.csv`：说明不是硬凑停表，而是用 16 次 verify、addr15 最后和输出匹配共同判定。
4. 展示 Core1 汇编：证明 Core1 用普通 MCU 指令完成计算和写回。

## 后续

V38 需要补上板验证。验证通过后，V38 可以替代 V34 成为最快已上板路线；如果 V38 上板不稳，展示仍以 V34 为主。
