# 路线 Ultra 开发与上板记录

日期：2026-07-04

## 当前状态

Ultra 路线已经完成 300 MHz MCU 工作时钟闭环。正式统计口径为 no-ILA、`flatten_hierarchy=none`、`max_dsp=0`、post-implementation timing report。

当前分层如下：

| 层级 | 路线 | 状态 | 价值 |
| --- | --- | --- | --- |
| 最新最快实现 | V38 | 300 MHz PASS，`cnt_test=85`，未上板 | 当前冲分候选 |
| 最快已上板 | V34 | 300 MHz PASS，`cnt_test=88`，已完成 no-ILA + ILA 上板验证 | 当前实物展示主线 |
| V34 复现 | V37 | 300 MHz PASS，`cnt_test=88` | 证明 V34 独立复现 |
| Core1 中间计算证明 | V33 | 300 MHz PASS，`cnt_test=135` | 证明不是 Core1 idle |
| 32-bit 合规展示 | V36 | 300 MHz PASS，`cnt_test=169` | 回答架构位宽质疑 |
| 稳定保底 | V22b | 300 MHz PASS，`cnt_test=173`，已上板 | 低风险备份 |

## 已完成并从待办剔除

1. V34 no-ILA bitstream 已生成。
2. V34 ILA 上板验证已完成。
3. V34 板上抓到 16 次 verify 写回，地址 0 到 15 全覆盖。
4. V34 addr15 是最后一次 verify 写，最终 `cnt_test=88`。
5. V34 验证后已重新下载 no-ILA bitstream。
6. V37 已完成：功能 PASS、bitstream PASS，但 WNS 未超过 V34。
7. V38 已完成：功能 PASS、300 MHz timing clean、`cnt_test=85`，成为新的最快实现路线。

## V38 关键结论

V38 的直接硬减等待扫描发现，低于 80 的 `CORE1_WAIT_STAGE2_NOP` 会出现停表提前风险。进一步二维扫描后确定：

```text
CORE1_WAIT_STAGE2_NOP=68
CORE1_WAIT_STAGE3_NOP=23
CORE1_FINAL_ADDR15_DELAY_NOP=9
```

该组合让 Core1 更早完成 Stage2/Stage3，但只延后最后一次 addr15 写回，使 `cnt_test` 的停止点重新对齐真正最后输出。

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 85 |
| 理论时间 | 0.283 us |
| WNS/TNS | +0.091 ns / 0.000 ns |
| LUT/FF | 2228 / 1619 |
| DSP/BRAM | 0 / 0 |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v38_dual_mcu_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit` |

## 下一步建议

1. 优先完成 V38 上板验证：先下载 no-ILA bitstream，看 `done` 是否稳定拉高。
2. 如果 no-ILA 正常，再生成 V38 ILA 版本，抓 `done/cnt_test/verify_we/verify_addr/verify_vector_out/Core0/Core1 verify 来源`。
3. V38 ILA 必须确认 16 次 verify 写回、addr15 最后写、输出与 `FFT_output.coe` 完全一致。
4. 若 V38 上板存在不稳定，展示时回退到已上板的 V34，V38 作为最新仿真和实现成绩。
5. V39 才进入更激进重构：让 Core1 前置参与 Stage1 或重新安排 shared RAM 依赖，目标继续低于 85cnt。

## 常用命令

V38 回归：

```powershell
cd routes_ultra\V38_dual_mcu_stage2_wait_reduce_300\mcu_fft_v38_dual_mcu_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V38 no-ILA 实现：

```powershell
cd routes_ultra\V38_dual_mcu_stage2_wait_reduce_300\mcu_fft_v38_dual_mcu_stage2_wait_reduce_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v38_stable_no_ila.tcl
```

V34 已上板主线回归：

```powershell
cd routes_ultra\V34_dual_mcu_schedule_300\mcu_fft_v34_dual_mcu_schedule_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```
