# V38 路线记录：Stage2 等待压缩实验

## 目标和结论

V34 的 `cnt_test=88` 已经完成上板验证。继续降低周期数时，最大的剩余等待点是：

```text
CORE1_WAIT_STAGE2_NOP=80
```

它用于等待 Core0 完成 Stage1 中 Core1 后续计算 `(5,7,W2)` 所需的 RAM5/RAM7 输入。V38 的扫描结果显示：不能只把等待从 80 硬降下去，因为会出现 addr15 提前触发停表；但如果只延后 Core1 最后一次 addr15 写回，就可以得到新的安全点：

```text
CORE1_WAIT_STAGE2_NOP=68
CORE1_WAIT_STAGE3_NOP=23
CORE1_FINAL_ADDR15_DELAY_NOP=9
```

该组合的官方样例 trace 满足 16 次 verify 写回、地址 0 到 15 全覆盖、addr15 最后写入，并把 `cnt_test` 从 V34 的 88 降到 85。

## 合格条件

单纯输出文件匹配还不够，因为之前已经出现过 addr15 提前写导致停表过早的假快。因此 V38 扫描同时检查：

1. 输出与 `FFT_output.coe` 一致。
2. `verify_we` 总数为 16。
3. verify 地址覆盖 0 到 15。
4. addr15 是最后一次 verify 写入。
5. `done` 后的 `cnt_test` 与 trace 口径一致。

## 扫描结果

第一轮只扫 `stage2_wait=40..80`、`final_addr15_delay=0`，只有 80 安全；55-59、68-71 虽然部分输出匹配，但 addr15 不是最后写，属于停表提前的假快。

第二轮扫描 `stage2_wait=55..80`、`final_addr15_delay=0..16`，找到最优安全点：

| `stage2_wait` | `final_addr15_delay` | `cnt_test` | `done cycles` | 最后 verify cycle | 结论 |
| ---: | ---: | ---: | ---: | ---: | --- |
| 68 | 9 | 85 | 141 | 138 | 最优安全点 |
| 69 | 8 | 85 | 141 | 138 | 等价安全点 |
| 70 | 7 | 85 | 141 | 138 | 等价安全点 |
| 71 | 6 | 85 | 141 | 138 | 等价安全点 |
| 80 | 0 | 88 | 144 | 142 | V34 基准 |

完整扫描记录见：

```powershell
results\sweep_stage2_wait.csv
results\sweep_stage2_wait_summary.txt
```

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机输入，seed=2026 到 2045 | PASS |
| `cnt_test` | 85 |
| 理论时间，300 MHz | 0.283 us |
| WNS/TNS | +0.091 ns / 0.000 ns |
| WHS/THS | +0.127 ns / 0.000 ns |
| LUT/FF | 2228 / 1619 |
| DSP/BRAM | 0 / 0 |
| DRC | 0 Error，仅 CFGBVS/CONFIG_VOLTAGE warning |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v38_dual_mcu_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit` |

说明：第一次使用默认实现策略时 WNS 为 `-0.072 ns`，不能作为正式结果。随后使用 `vivado/run_v38_stable_no_ila.tcl` 重新实现，WNS 转正到 `+0.091 ns`，因此正式统计采用 stable 实现目录。

## 合规边界

V38 没有新增硬件计算单元，只改变 Core1 普通指令流中的等待数量和最后一次 `STR` 的位置：

- Core0/Core1 仍是两个完整 MCU。
- Core1 仍执行 `LDR/ADD/SUB/MUL/STR/NOP` 等普通指令。
- shared RAM 只做普通存储，不做 FFT 计算。
- 没有 `BFY/FFT_STAGE/CMUL/CADD/CSUB` 等专用指令。
- 没有 FFT engine、butterfly unit、DMA 或 coprocessor。
- DSP=0。

## 后续建议

V38 目前是新的最快实现路线，但尚未实物上板。下一步应先完成 V38 no-ILA 上板下载，观察 `done/cnt_test`，再生成 ILA 版本确认 16 次 verify 写回、addr15 最后写、输出全部匹配。
