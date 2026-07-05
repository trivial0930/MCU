# 当前结果速览

更新时间：2026-07-05

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 内部 PLLE2 生成 300 MHz
- 正式资源和速度统计：关闭 ILA，`flatten_hierarchy=none`，`max_dsp=0`
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：全系统 wall-clock 计数，从有效输入读入开始，到最后一轮可信 verify 写回完成

## Ultra 300 MHz 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V59_octa_fast_stop_300` | PASS，已上板，ILA 已证明 fast-stop 非提前停表 | 49 | 0.163 us | +0.095 ns | 8677 | 6451 | 0 | 当前最快且已上板路线 |
| 2 | `V58_octa_pairfold_balanced_300` | PASS，功能候选 | 50 | 0.167 us | - | - | - | 0 | V59 的稳定功能基线 |
| 3 | `V57_octa_memory_bank_pairfold_300` | PASS，功能候选 | 52 | 0.173 us | - | - | - | 0 | 奇数核 pair-fold 中间版 |
| 4 | `V56_octa_bucketed_output_owner_300` | PASS，功能候选 | 54 | 0.180 us | - | - | - | 0 | 奇数核 `±91` bucket 版 |
| 5 | `V54_octa_output_owner_300` | PASS，已上板验证 | 59 | 0.197 us | +0.095 ns | 8733 | 6476 | 0 | 稳定回退路线 |
| 6 | `V53_quad_output_owner_300` | PASS，bitstream 已生成 | 72 | 0.240 us | +0.089 ns | 5002 | 3718 | 0 | 四核输出归属路线 |
| 7 | `V45_stage2_wait_reduce_300` | PASS，已上板验证 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 双核低资源备份 |
| 8 | `V42_v34_board_verified_300` | PASS，已上板证据固化 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 稳定回退路线 |

不推荐作为最终展示主线：`V24_load_forward_300`、`V27a_mul1_lut_300`、`V27b_hybrid_mul_300`，原因是 300 MHz timing 未通过。

## V59 上板结论

V59 已完成以下验证：

- no-ILA bitstream 可下载到 `xc7k160t_0`，最终板卡已回刷 no-ILA 正式版本。
- ILA 调试版本在 300 MHz 下 timing clean，WNS/TNS = `+0.139 ns / 0.000 ns`。
- ILA 触发条件为 `fast_stop_pulse_dbg == 1`。
- 首次 fast-stop 样本中，16 次 verify 写回已经全部出现，地址 0 到 15 全覆盖。
- 最后一笔写回为 addr15，写入值与期望输出一致。
- ILA 捕获中 `verify_done_mask_next=0xffff`、`owner_seen=0xff`、`owner_done_next=0xff`，证明停表发生在全部 owner 完成后。
- `compare_v59_ila_capture.py` 输出 `overall_status=PASS`。

关键证据文件：

- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_ila_fast_stop_capture.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_hw_compare.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/v59_fast_stop_proof.csv`
- `routes_ultra/V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300/board_validation/FAST_STOP_PROOF.md`

## 本轮 V56-V59 结论

V56-V59 都没有增加 FFT 专用硬件，也没有新增专用指令。速度收益来自八个完整 MCU core 的输出归属拆分后，对奇数输出核的普通指令序列做代数调度：

- V56：把奇数输出中的多个 `±91` 乘法项按 real/imag bucket 聚合，最后只执行两次普通 `MUL`，`cnt_test=54`。
- V57：对 `±91` 的两组输入 pair 做 fold，减少 add/sub 指令，`cnt_test=52`。
- V58：配平 `X3/X5` 两个奇数核，去掉额外取负指令，`cnt_test=50`。
- V59：在 V58 基础上使用同拍 owner-complete 停表，保持 16 次 verify 写回和最后 addr15 可信写回，`cnt_test=49`，300 MHz WNS `+0.095 ns`。

## 当前建议

- 课堂速度展示：使用 V59。它是当前最快、已上板、已完成 ILA fast-stop 证明的路线。
- 稳定回退展示：使用 V54。它比 V59 慢，但上板链路更早固化，适合作为保底说明。
- 低资源备份：使用 V45。资源明显小于八核路线，且已上板验证。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
