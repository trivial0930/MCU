# V53 四核输出归属路线说明

## 来源

V53 从 `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` 复制。V45 是此前最快已上板路线，`cnt_test=85`，300MHz no-ILA WNS 为 `+0.091 ns`。

## 目标

在继续满足课程和老师要求的前提下，探索四个完整 MCU core 的输出归属拆分：

- 不新增 FFT engine、butterfly_unit、fft_stage_unit、twiddle_engine、DMA controller 或 coprocessor。
- 不新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等专用指令。
- Core0/Core1/Core2/Core3 均执行普通 32-bit ARM-like 指令 ROM。
- verify RAM 必须由普通 `STR` 指令写入。
- DSP 必须为 0。
- 官方样例 + 20 组随机必须 PASS。
- `cnt_test` 必须保持全系统 wall-clock 计数。

## 四核任务划分

| Core | 主要任务 | verify 输出归属 |
| --- | --- | --- |
| Core0 | Stage1/Stage2 主生产链；Stage3 `(0,1,W0)` | 0, 4, 8, 12 |
| Core1 | Stage2 `(5,7,W2)`；Stage3 `(4,5,W0)` | 1, 5, 9, 13 |
| Core2 | Stage3 `(2,3,W0)` | 2, 6, 10, 14 |
| Core3 | Stage3 `(6,7,W0)` | 3, 7, 11, 15 |

Core1/2/3 的等待参数：

```text
CORE1_WAIT_STAGE2_NOP = 68
CORE1_WAIT_STAGE3_NOP = 23
CORE2_WAIT_STAGE3_NOP = 108
CORE3_WAIT_STAGE3_NOP = 92
```

## 共享 RAM 与同步

- shared RAM 仍然是普通存储器，读写由普通 `LDR/STR` 发起。
- Core0 写入 Stage1/Stage2 的中间值。
- Core1 写入 `(5,7,W2)` 的 Stage2 中间值。
- Core2/Core3 在本路线只读取 shared RAM，不向 shared RAM 写入，因此综合端口中关闭 Core2/Core3 写使能。
- verify 完成条件由 `done_mask` 聚合 16 个 verify 地址得到，最后可信写入为 cycle 126 的 Core0 地址 12。

## 时序优化记录

300MHz 初版 post-route WNS 为负。修复过程如下：

| 步骤 | 变化 | 结果 |
| --- | --- | --- |
| 初始四核实现 | 四写口 verify RAM + shared RAM 多写路径 | post-route WNS 为负 |
| verify RAM bank 化 | 按输出归属拆成四个单写口 bank | WNS 改善，但 shared RAM 仍为瓶颈 |
| aligned-base offset 快路径 | memory offset 直接使用立即数低 8 位，base 高位只负责区域选择 | 300MHz route 后 WNS 转正 |

该优化不硬编码输入数据，也不把 FFT 计算做成固定硬件网络；它只缩短普通 `LDR/STR` 的地址形成路径。

## 最终结果

| 项目 | V45 | V53 |
| --- | ---: | ---: |
| core 数 | 2 | 4 |
| `cnt_test` | 85 | 72 |
| 300MHz 理论时间 | 0.283 us | 0.240 us |
| WNS/TNS | +0.091 / 0.000 ns | +0.089 / 0.000 ns |
| WHS/THS | +0.127 / 0.000 ns | +0.065 / 0.000 ns |
| LUT | 2228 | 5002 |
| FF | 1619 | 3718 |
| DSP | 0 | 0 |
| BRAM | 0 | 0 |
| 官方样例 + 20 随机 | PASS | PASS |
| 上板状态 | 已验证 | 待上板 |

## 建议

V53 可作为新的最快 no-ILA 候选路线推进上板；V45 仍建议保留为当前最快已上板备份。若后续上板验证 V53 通过，可以把主线展示路线从 V45 切换到 V53。

