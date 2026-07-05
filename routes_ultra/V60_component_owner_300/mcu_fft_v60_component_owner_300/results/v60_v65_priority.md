# V60-V65 优先级评估

本轮优先选择 V60，因为它把 16 个输出分量直接分配给 16 个完整 MCU core，不需要 partial-sum 合并，也不需要 helper core 之间的 shared-RAM 同步。该路线已经完成 RTL、汇编生成、官方样例 + 20 随机回归、合规审计和 300 MHz no-ILA bitstream。

## 当前排序

| 优先级 | 路线 | 当前处理 |
| ---: | --- | --- |
| 1 | V60 16 核 real/imag component-owner | 已完成，当前最快 bitstream 路线 |
| 2 | V65 多核 cluster / routing | 暂缓；若 V60 上板或 ILA 版本出现时序压力，再用作布线稳定化路线 |
| 3 | V61 12 核 helper | 暂缓；helper 同步开销预计抵消收益 |
| 4 | V62 16 核 partial-sum | 暂缓；需要合并 partial sum，verify 路径更复杂 |
| 5 | V63 16 核 verify/output helper | 暂缓；verify helper 容易被质疑不是 owner core 普通 `STR` |
| 6 | V64 24/32 核 term-owner | 暂缓；合并网络和 routing 风险最高 |

## 是否继续开更高路线

当前 V60 已经把 `cnt_test` 从 V59 的 49 降到 38，并且 300 MHz timing clean。继续开 V61-V64 大概率需要额外合并/同步，未必能低于 38；V65 的主要价值不是降低 `cnt_test`，而是提升上板和 ILA 版本的时序余量。

建议下一步先做 V60 上板和 ILA 可信停表证明，再决定是否开 V65。
