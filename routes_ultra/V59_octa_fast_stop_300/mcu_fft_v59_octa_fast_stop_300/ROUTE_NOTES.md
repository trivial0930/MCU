# V59 路线说明

## 来源

V59 复制自 `routes_ultra/V58_octa_pairfold_balanced_300/mcu_fft_v58_octa_pairfold_balanced_300`。

## 实现内容

- 保留 V58 的八核 output-owner 计算程序。
- 保留四个奇数核 46 条指令、四个偶数核 39 条指令的配平结果。
- 保持每个 core 通过普通 `LDR/ADD/SUB/MUL/STR` 计算自己负责的输出。
- 将 `cnt_test_unit.stop_pulse` 从寄存后一拍的 `verify_complete_pulse_q` 改为同拍的 `verify_complete_pulse_raw`。
- `verify_complete_pulse_raw` 由 `owner_done_next == 8'hff` 产生，含义是 8 个 owner core 都已完成第二次普通 `STR` verify 写回。
- ILA 调试版额外暴露 `verify_done_mask`、`owner_seen_dbg`、`owner_done_dbg` 和 `fast_stop_pulse_dbg`，这些端口只在 `ENABLE_ILA` 下存在，不影响 no-ILA 正式 bitstream。

## 结果对比

| 项目 | V54 | V58 | V59 |
| --- | ---: | ---: | ---: |
| `cnt_test` | 59 | 50 | 49 |
| 300 MHz 理论时间 | 0.197 us | 0.167 us | 0.163 us |
| 指令总数 | 452 | 340 | 340 |
| 官方样例 + 20 随机 | PASS | PASS | PASS |
| WNS/TNS | +0.095 / 0.000 ns | 未单独实现 | +0.095 / 0.000 ns |
| WHS/THS | +0.072 / 0.000 ns | 未单独实现 | +0.074 / 0.000 ns |
| LUT | 8733 | - | 8677 |
| FF | 6476 | - | 6451 |
| DSP | 0 | 0 | 0 |
| 上板状态 | 已验证 | 未上板 | 已验证 |

## V59 上板验证摘要

| 验证项 | 结果 |
| --- | --- |
| no-ILA 下载 | PASS，`xc7k160t_0` 可识别并完成下载 |
| no-ILA ILA 数量 | 0 |
| ILA bitstream 实现 | PASS，300 MHz WNS/TNS = +0.139 / 0.000 ns |
| ILA 捕获触发 | PASS，触发条件 `fast_stop_pulse_dbg == 1` |
| verify 写回数 | 16 |
| verify 地址覆盖 | 0..15 全覆盖 |
| 最后一笔 verify | addr15，写入值 `d874`，与期望一致 |
| fast-stop 是否提前 | 否，`fast_stop_not_early=PASS` |
| 输出比对 | PASS |
| 验证后状态 | 已回刷 no-ILA 正式 bitstream |

## fast-stop 证明要点

首次 `fast_stop_pulse_dbg` 出现的 ILA 样本中：

- `verify_we_at_first_fast_stop=0xaa`，说明奇数 owner core 在这一拍写入最后一批输出。
- `writes_at_or_before_first_fast_stop=16`。
- `unique_addrs_at_or_before_first_fast_stop=16`。
- `verify_done_mask_q_at_first_fast_stop=0x55ff`，这是触发边沿前的寄存值。
- `verify_done_mask_next_at_first_fast_stop=0xffff`，这是 RTL 同拍停表实际使用的 next 值。
- `owner_seen_at_first_fast_stop=0xff`。
- `owner_done_q_at_first_fast_stop=0x55`，这是触发边沿前已有完成 owner。
- `owner_done_next_at_first_fast_stop=0xff`，说明同拍写入后 8 个 owner 全部完成。

因此 V59 的 `cnt_test=49` 不是通过提前停表得到的，而是在最后一批可信 verify 写回同拍结束计数。

## 合规性结论

V59 仍保持 32-bit ARM-like 普通指令 MCU 路线：

- 无 FFT engine。
- 无 butterfly unit。
- 无 DMA controller。
- 无 coprocessor。
- 无 FFT、复数、蝶形专用 opcode。
- shared RAM 和 verify RAM 只承担普通存储功能。
- verify RAM 由普通 `STR` 指令写入。
- DSP 使用量为 0。

## 推荐结论

V59 建议作为当前新主线。V54 可作为稳定回退路线，V45 可作为低资源备份路线。本阶段不继续探索更高版本，优先把 V59 的上板、ILA 证明和合规材料讲清楚。
