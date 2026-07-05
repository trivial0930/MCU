# 当前结果速览

更新时间：2026-07-05

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 内部 PLLE2 生成 300 MHz
- 正式资源和速度统计：关闭 ILA，`flatten_hierarchy=none`，`max_dsp=0`
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：全系统 wall-clock 计数，从首个有效 FFT 输入读取开始，到最后一批可信 verify 写回完成后停止

## 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V60_component_owner_300` | PASS，bitstream 已生成，尚未上板 | 38 | 0.127 us | +0.014 ns | 16970 | 13203 | 0 | 当前最快实现候选 |
| 2 | `V59_octa_fast_stop_300` | PASS，已上板，ILA 已证明 fast-stop 非提前停表 | 49 | 0.163 us | +0.095 ns | 8677 | 6451 | 0 | 当前最快已上板路线 |
| 3 | `V58_octa_pairfold_balanced_300` | PASS，功能候选 | 50 | 0.167 us | - | - | - | 0 | V59 的功能基线 |
| 4 | `V57_octa_memory_bank_pairfold_300` | PASS，功能候选 | 52 | 0.173 us | - | - | - | 0 | pair-fold 中间版本 |
| 5 | `V56_octa_bucketed_output_owner_300` | PASS，功能候选 | 54 | 0.180 us | - | - | - | 0 | `±91` bucket 版本 |
| 6 | `V54_octa_output_owner_300` | PASS，已上板 | 59 | 0.197 us | +0.095 ns | 8733 | 6476 | 0 | 稳定回退路线 |
| 7 | `V53_quad_output_owner_300` | PASS，bitstream 已生成 | 72 | 0.240 us | +0.089 ns | 5002 | 3718 | 0 | 四核输出归属路线 |
| 8 | `V45_stage2_wait_reduce_300` | PASS，已上板 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 双核低资源备份 |
| 9 | `V42_v34_board_verified_300` | PASS，已上板 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 稳定回退路线 |

## V60 摘要

V60 使用 16 个完整 MCU core，每个 core 负责一个 real/imag 输出分量和一个 verify 地址。该路线没有新增 FFT engine、butterfly unit、DMA、coprocessor 或专用 FFT opcode，verify 仍由普通 `STR` 指令写入。

关键结果：

- 官方样例 + 20 随机：PASS
- `cnt_test=38`
- 300 MHz 理论时间：`0.127 us`
- no-ILA WNS/TNS：`+0.014 ns / 0.000 ns`
- LUT/FF/DSP/BRAM：`16970 / 13203 / 0 / 0`
- DRC：0 checks found
- bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300/mcu_fft_board.runs/impl_1/board_top.bit`

V60 尚未上板，也还没有 ILA 停表证明。若用于最终展示，下一步应先做 V60 上板和 ILA 可信停表证明。

## V59 上板结论

V59 已完成以下验证：

- no-ILA bitstream 可下载到 `xc7k160t_0`。
- ILA 调试版本在 300 MHz 下 timing clean。
- 首次 `fast_stop_pulse_dbg` 出现时，16 次 verify 写回已经全部出现，地址 0 到 15 全覆盖。
- 最后一批写回包含 addr15，写入值与期望输出一致。
- `compare_v59_ila_capture.py` 输出 `overall_status=PASS`。

关键证据文件：

- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_ila_fast_stop_capture.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_hw_compare.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_fast_stop_proof.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/FAST_STOP_PROOF.md`

## 当前建议

- 最高速度候选：V60。先完成上板和 ILA 证明后，再考虑替代 V59 作为展示主线。
- 课堂稳妥展示：V59。它速度第二，但已有完整上板和 fast-stop 证明。
- 稳定回退：V54。
- 低资源备份：V45。
