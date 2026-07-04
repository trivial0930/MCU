# V37 路线记录：V34 稳定化实现

## 定位

V34 已经完成 no-ILA 和 ILA 上板验证，板上 16 次 verify 写回均与 `FFT_output.coe` 匹配，最终 `cnt_test=88`。因此附件分析中的“先完成 V34 上板验证”已经从待办中剔除，本路线从第二优先级继续：把 V34 做成更稳定的 300 MHz 交付候选。

V37 不改变 V34 的计算分工：

- Core0/Core1 仍然是两个完整 MCU。
- Core0/Core1 均执行普通指令 ROM。
- Core1 仍负责 Stage2 `(5,7,W2)` 以及后半 Stage3 输出。
- `CORE1_WAIT_STAGE2_NOP=80`。
- `CORE1_WAIT_STAGE3_NOP=23`。
- 没有新增 `BFY`、`FFT_STAGE`、`CMUL`、`CADD`、`CSUB` 等专用指令。
- 没有 FFT engine、butterfly unit、DMA 或 coprocessor。
- `SYNTH_MAX_DSP=0`，正式统计关闭 ILA。

## 稳定化策略

本轮先不改 RTL 和汇编调度，而是尝试使用更偏性能收敛的 Vivado 实现策略：

- implementation strategy 优先尝试 `Performance_ExplorePostRoutePhysOpt`。
- 保留 `phys_opt_design`。
- 尝试 `opt_design/place_design/phys_opt_design/route_design` 的探索型 directive。
- 如果本机 Vivado 不支持某个 strategy 或 directive，脚本会自动降级到默认 `Performance_Explore`，并把降级信息写入状态文件。

这样做的原因是 V34 已经是目前最快、且上板验证通过的路线；V37 需要优先证明“同一逻辑是否能获得更厚的 timing margin”，而不是先冒险改动计算路径。

## 目标结果

| 项目 | 目标 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机输入 | PASS |
| `cnt_test` | 88 |
| MCU 频率 | 300 MHz |
| DSP | 0 |
| WNS | 优先争取高于 V34 的 +0.056 ns |

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机输入，seed=2026 到 2045 | PASS |
| `cnt_test` | 88 |
| 理论时间，300 MHz | 0.293 us |
| WNS/TNS | +0.056 ns / 0.000 ns |
| WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF | 2226 / 1618 |
| DSP/BRAM | 0 / 0 |
| DRC | 0 Error，仅 CFGBVS/CONFIG_VOLTAGE warning |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v37_dual_mcu_v34_stable_300/mcu_fft_board.runs/impl_1/board_top.bit` |

本次策略成功生成 no-ILA bitstream，但 WNS 没有超过 V34 的 +0.056 ns。Vivado post-route phys_opt 看到 WNS 已非负后没有继续修改网表，因此 V37 的价值是“独立复现 V34 逻辑和成绩”，不能宣传为比 V34 timing 更稳的改进版。

最差 setup path 仍在 Core0 内部 EX 到 WB 数据路径：

```text
Source:      u_mcu_top/u_mcu_core0/ex_op1_reg[0]_replica/C
Destination: u_mcu_top/u_mcu_core0/wb_wdata_reg[26]/D
Slack:       +0.056 ns
```

这说明后续若继续优化，主要收益应来自调度压缩或 Core0 数据通路切分，而不是 verify 写仲裁的小修小补。

## 结论

V37 作为 V34 的稳定化尝试，功能、资源、bitstream 均通过，但没有获得更高 WNS。因此当前展示排序仍保持：

1. V34：最快且已上板验证主线。
2. V37：V34 等价复现和工具策略实验，不作为新的最快路线。
3. V38/V39：继续压低 `CORE1_WAIT_STAGE2_NOP` 或前置 Core1 Stage1 参与，才可能继续低于 88cnt。
