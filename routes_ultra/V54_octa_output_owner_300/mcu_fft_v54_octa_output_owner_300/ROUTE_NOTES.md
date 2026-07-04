# V54 路线说明

## 来源

V54 从 `routes_ultra/V53_quad_output_owner_300/mcu_fft_v53_quad_output_owner_300` 复制。V53 是四核输出归属路线，`cnt_test=72`，300 MHz no-ILA WNS `+0.089 ns`。

## 目标

在继续满足课程和老师约束的前提下，将输出归属拆分扩展到 8 个完整 MCU core：

- 不新增 FFT engine、butterfly_unit、fft_stage_unit、twiddle_engine、DMA controller 或 coprocessor。
- 不新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等专用指令。
- Core0..Core7 均执行普通 32-bit ARM-like 指令 ROM。
- verify RAM 必须由普通 `STR` 指令写入。
- DSP 必须为 0。
- 官方样例 + 20 组随机必须 PASS。
- `cnt_test` 必须保持全系统 wall-clock 计数。

## 八核任务划分

| Core | 任务 | verify 地址 |
| --- | --- | --- |
| Core0 | 计算 `X0.real` 和 `X0.imag` | 0, 8 |
| Core1 | 计算 `X1.real` 和 `X1.imag` | 1, 9 |
| Core2 | 计算 `X2.real` 和 `X2.imag` | 2, 10 |
| Core3 | 计算 `X3.real` 和 `X3.imag` | 3, 11 |
| Core4 | 计算 `X4.real` 和 `X4.imag` | 4, 12 |
| Core5 | 计算 `X5.real` 和 `X5.imag` | 5, 13 |
| Core6 | 计算 `X6.real` 和 `X6.imag` | 6, 14 |
| Core7 | 计算 `X7.real` 和 `X7.imag` | 7, 15 |

## 存储和同步

- `test_ROM` 被复制为 8 份，只作为只读输入存储。
- 每个 core 通过普通 `LDR` 访问自己的 `test_ROM` 端口。
- V54 不使用 shared RAM 做跨 core 计算交换，减少同步等待。
- `verify_RAM_oct` 按输出 owner 拆成 8 个单写 bank。
- `mcu_top` 用 16 bit `done_mask` 记录 16 个 verify 地址是否都被写入。
- `cnt_test_unit` 从任一 core 第一次有效读取输入开始计数，到 `done_mask` 将变为 `16'hffff` 的周期停止。

## 优化记录

| 步骤 | 变化 | 结果 |
| --- | --- | --- |
| V54 初版 | 8 核 output-owner，奇数核重复计算 `×91` | PASS，`cnt_test=78` |
| 乘法结果复用 | 奇数核内用 `R14/R15` 复用同一 pair 的 `×91` 结果 | PASS，`cnt_test=58` |
| DRC 清理 | 在 XDC 中补 `CFGBVS=VCCO` 和 `CONFIG_VOLTAGE=3.3` | DRC `Checks found: 0` |

曾尝试把累加器清零从 `MOVR` 改成更早的 `MOVI #0`，总仿真周期减少但第一次输入读取也提前，导致合法 `cnt_test` 从 58 变为 59。该修改已放弃，最终保留 `cnt_test=58` 的指令时序。

## 最终结果

| 项目 | V45 | V53 | V54 |
| --- | ---: | ---: | ---: |
| core 数 | 2 | 4 | 8 |
| `cnt_test` | 85 | 72 | 58 |
| 300 MHz 理论时间 | 0.283 us | 0.240 us | 0.193 us |
| WNS/TNS | +0.091 / 0.000 ns | +0.089 / 0.000 ns | +0.011 / 0.000 ns |
| WHS/THS | +0.127 / 0.000 ns | +0.065 / 0.000 ns | +0.063 / 0.000 ns |
| LUT | 2228 | 5002 | 8851 |
| FF | 1619 | 3718 | 6519 |
| DSP | 0 | 0 | 0 |
| BRAM | 0 | 0 | 0 |
| 官方样例 + 20 随机 | PASS | PASS | PASS |
| 上板状态 | 已验证 | 待上板 | 待上板 |

## 建议

V54 建议作为新的最快 no-ILA 候选推进上板验证。若实物验证 PASS，可将展示主线从 V45 切换到 V54；若上板调试临时受阻，V45 仍是最快已验证备份。
