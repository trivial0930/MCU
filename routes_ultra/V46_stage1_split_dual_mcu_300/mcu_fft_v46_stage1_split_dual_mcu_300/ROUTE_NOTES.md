# V46 路线记录：Stage1 Split Dual MCU 300 MHz

## 来源

V46 从 `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` 复制。V45 已经是当前最快且已上板路线，`cnt_test=85`，300 MHz WNS `+0.091 ns`，DSP=0。

## Core1 新增 Stage1 任务

Core1 新增两段普通 Stage1 下半支路计算：

- 读取 `RAM20..23`，执行 `(1,5,W1)` 下半支路，写回 `RAM10/RAM11`。
- 读取 `RAM24..27`，执行 `(3,7,W3)` 下半支路，写回 `RAM14/RAM15`。

这些计算全部使用普通 `LDR/SUB/ADD/MUL/STR` 指令，没有新增专用指令。

## 从 Core0 移到 Core1 的计算

| 计算 | V45 | V46 |
| --- | --- | --- |
| `(1,5,W1)` 上半支路 `RAM2/RAM3` | Core0 | Core0 |
| `(1,5,W1)` 下半支路 `RAM10/RAM11` | Core0 | Core1 |
| `(3,7,W3)` 上半支路 `RAM6/RAM7` | Core0 | Core0 |
| `(3,7,W3)` 下半支路 `RAM14/RAM15` | Core0 | Core1 |

## shared RAM 新增交换值

Core0 新增普通 `STR`，把原始输入转交给 Core1：

- `RAM20..23`：`x1/x5` 的 real/imag。
- `RAM24..27`：`x3/x7` 的 real/imag。

shared RAM 仍只做普通读写存储，不做计算。

## 同步点变化

| 同步点 | V45 | V46 |
| --- | ---: | ---: |
| Core1 Stage2 前等待 | 68 | 0 |
| Core1 Stage3 前等待 | 23 | 0 |
| final addr15 delay | 9 | 21 |

V46 虽然消除了 Stage2/Stage3 等待，但 addr15 过早写会造成假停表。扫描证明 `final_addr15_delay < 21` 时 addr15 不是最后一次可信写回；最低合法值为 21。

## 功能和速度

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 随机 | PASS |
| verify 写回次数 | 16 |
| addr15 是否最后写 | YES |
| `cnt_test` | 85 |
| 相比 V45 | 无下降 |
| 结论 | 合规可行，但不是有效优化 |

## Vivado 300 MHz no-ILA

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.029 ns |
| TNS | 0.000 ns |
| WHS | +0.119 ns |
| THS | 0.000 ns |
| LUT | 2231 |
| FF | 1629 |
| DSP | 0 |
| BRAM | 0 |

Bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v46_stage1_split_dual_mcu_300/mcu_fft_board.runs/impl_1/board_top.bit
```

## 合规性

- 保持两个完整 MCU core。
- Core0/Core1 都执行普通 32-bit ARM-like 指令 ROM。
- Core1 真实执行 Stage1 普通指令。
- 无 FFT engine。
- 无 butterfly unit。
- 无 fft_stage_unit。
- 无 twiddle engine。
- 无 DMA controller。
- 无 coprocessor。
- 无 BFY/FFT_STAGE/BUTTERFLY/CMUL/CADD/CSUB 等专用指令。
- verify RAM 仍由普通 `STR` 写入。
- `cnt_test` 口径未修改，仍由全系统最后一次 addr15 写回停表。

## 是否建议作为新主线

不建议。V46 的最小 Stage1 迁移证明了方向可行，但合法最优点仍为 `cnt_test=85`，没有超过 V45，并且 WNS 从 V45 的 `+0.091 ns` 降到 `+0.029 ns`。当前主线仍应保持 V45；V46 作为负结果和下一步更深拆分的依据保留。
