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
| 1 | `V61_testrom_addr_stable_300` | PASS，bitstream 已生成，尚未上板 | 38 | 0.127 us | +0.162 ns | 16712 | 13140 | 0 | 当前最快且 WNS 更稳的 no-ILA 候选 |
| 2 | `V60_component_owner_300` | PASS，已上板，ILA 证明 fast-stop 非提前停表 | 38 | 0.127 us | +0.014 ns | 16970 | 13203 | 0 | 当前最快已上板路线 |
| 3 | `V59_octa_fast_stop_300` | PASS，已上板，ILA 证明 fast-stop 非提前停表 | 49 | 0.163 us | +0.095 ns | 8677 | 6451 | 0 | 稳妥八核展示路线 |
| 4 | `V58_octa_pairfold_balanced_300` | PASS，功能候选 | 50 | 0.167 us | - | - | - | 0 | V59 的功能基线 |
| 5 | `V57_octa_memory_bank_pairfold_300` | PASS，功能候选 | 52 | 0.173 us | - | - | - | 0 | pair-fold 中间版本 |
| 6 | `V56_octa_bucketed_output_owner_300` | PASS，功能候选 | 54 | 0.180 us | - | - | - | 0 | bucket 版本 |
| 7 | `V54_octa_output_owner_300` | PASS，已上板 | 59 | 0.197 us | +0.095 ns | 8733 | 6476 | 0 | 稳定回退路线 |
| 8 | `V53_quad_output_owner_300` | PASS，bitstream 已生成 | 72 | 0.240 us | +0.089 ns | 5002 | 3718 | 0 | 四核输出归属路线 |
| 9 | `V45_stage2_wait_reduce_300` | PASS，已上板 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 双核低资源备份 |
| 10 | `V42_v34_board_verified_300` | PASS，已上板 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 早期双核稳定路线 |

## V61 摘要

V61 是 V60 的 WNS 稳定化路线。它仍然使用 16 个完整 MCU core，每个 core 负责一个 real/imag 输出分量和一个 verify 地址。V61 没有改变 `cnt_test`，也没有引入专用 FFT 硬件；唯一 RTL 改动是去掉 test-ROM 地址端口上不必要的 `is_test_rom` 门控，避免 test-ROM 地址判断进入最差读路径。

关键结果：

- 官方样例 + 20 随机：PASS
- 基础指令集测试：PASS
- `cnt_test=38`
- 300 MHz 理论时间：`0.127 us`
- FFT 速度：`789.47 万次/秒`
- no-ILA WNS/TNS：`+0.162 ns / 0.000 ns`
- LUT/FF/DSP/BRAM：`16712 / 13140 / 0 / 0`
- DRC：0 checks found
- Methodology：0 checks found
- bitstream：`D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300/mcu_fft_board.runs/impl_1/board_top.bit`
- 上板状态：尚未上板验证

## V60 已上板结论

V60 已完成以下验证：

- no-ILA bitstream 可下载到 `xc7k160t_0`。
- ILA 证明版本 300 MHz timing clean。
- 首次 `fast_stop_pulse_dbg` 出现时，16 次 verify 写回已经全部出现，地址 0 到 15 全覆盖。
- 最后一批写回包含 addr15，写入值与期望输出一致。
- `compare_v60_ila_capture.py` 输出 `overall_status=PASS`。

关键证据文件：

- `routes_ultra/V60_component_owner_300/mcu_fft_v60_component_owner_300/board_validation/BOARD_VALIDATION_REPORT.md`
- `routes_ultra/V60_component_owner_300/mcu_fft_v60_component_owner_300/board_validation/v60_hw_compare_status.txt`
- `routes_ultra/V60_component_owner_300/mcu_fft_v60_component_owner_300/board_validation/v60_fast_stop_proof.csv`

## 当前建议

- 最高速度且更稳的 no-ILA 候选：V61。它已经完成功能回归、基础指令集测试和 300 MHz bitstream，WNS 明显优于 V60，但还需要上板。
- 当前最快已上板路线：V60。它和 V61 一样 `cnt_test=38`，并且已有 no-ILA 上板和 ILA fast-stop 证明。
- 稳妥八核展示：V59。它速度第二，资源更低，也有完整上板和 fast-stop 证明。
- 稳定回退：V54。
- 低资源备份：V45。

