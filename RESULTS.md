# 当前结果速览

更新时间：2026-07-05

## 统一口径

- 目标器件：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- Ultra MCU 工作时钟：`board_top.v` 内部 PLLE2 生成 300 MHz
- 正式资源和速度统计：关闭 ILA，`flatten_hierarchy=none`，`max_dsp=0`
- 回归：官方样例 + 20 组随机输入，seed=2026
- `cnt_test`：从有效输入读取开始，到最后一轮可信 verify 写回完成

## Ultra 300 MHz 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | 理论时间 | WNS | LUT | FF | DSP | 结论 |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `V59_octa_fast_stop_300` | PASS，bitstream 已生成，待上板 | 49 | 0.163 us | +0.095 ns | 8677 | 6451 | 0 | 当前最快 no-ILA 候选 |
| 2 | `V58_octa_pairfold_balanced_300` | PASS，功能候选 | 50 | 0.167 us | - | - | - | 0 | V59 的稳定功能基线，未单独跑实现 |
| 3 | `V57_octa_memory_bank_pairfold_300` | PASS，功能候选 | 52 | 0.173 us | 未单独跑实现 | - | - | 0 | 奇数核 pair-fold 中间版 |
| 4 | `V56_octa_bucketed_output_owner_300` | PASS，功能候选 | 54 | 0.180 us | 未单独跑实现 | - | - | 0 | 奇数核 `±91` bucket 版 |
| 5 | `V54_octa_output_owner_300` | PASS，已上板验证 | 59 | 0.197 us | +0.095 ns | 8733 | 6476 | 0 | 当前最快已上板路线 |
| 6 | `V53_quad_output_owner_300` | PASS，bitstream 已生成 | 72 | 0.240 us | +0.089 ns | 5002 | 3718 | 0 | 四核输出归属路线 |
| 7 | `V45_stage2_wait_reduce_300` | PASS，已上板验证 | 85 | 0.283 us | +0.091 ns | 2228 | 1619 | 0 | 双核低资源备份 |
| 8 | `V42_v34_board_verified_300` | PASS，已上板证据固化 | 88 | 0.293 us | +0.056 ns | 2228 | 1615 | 0 | 稳定回退路线 |

不推荐作为最终展示主线：`V24_load_forward_300`、`V27a_mul1_lut_300`、`V27b_hybrid_mul_300`，原因是 300 MHz timing 未通过。

## 本轮 V56-V59 结论

V56-V59 都没有增加 FFT 专用硬件，也没有新增专用指令。速度收益来自八个完整 MCU core 的输出归属拆分后，对奇数输出核的普通指令序列做代数调度：

- V56：把奇数输出中的多个 `±91` 乘法项先按 real/imag bucket 聚合，最后只执行两次普通 `MUL`，`cnt_test=54`。
- V57：对 `±91` 的两组输入 pair 做 fold，减少 add/sub 指令，`cnt_test=52`。
- V58：配平 `X3/X5` 两个奇数核，去掉额外取负指令，`cnt_test=50`。
- V59：在 V58 基础上使用同拍 owner-complete 停表，保持 16 次 verify 写回和最后 addr15 可信写回，`cnt_test=49`，300 MHz WNS `+0.095 ns`。

## 当前建议

- 课堂稳妥展示：使用 V54，因为它已经完成 no-ILA 下载、ILA 抓波、16 次 verify 写回、输出比对和最终 no-ILA 回刷。
- 最新速度展示：使用 V59，准备功能回归、Vivado timing/utilization/DRC 和 bitstream 状态文件；上板前建议再用 ILA 做一次同样的 verify 写回抓取。
- 低资源备份：使用 V45，资源明显小于八核路线，且已上板验证。

## Route A 130 MHz 上板结果

`routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul` 已完成 130 MHz PLL 上板验证，`cnt_test=157`，理论时间约 `1.208 us`，DSP=0。该路线保留为非 Ultra 的稳定上板资料。
