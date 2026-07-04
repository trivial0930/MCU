# 路线 A 速度与效率榜

生成时间：2026-07-04

运行口径：

- Vivado：2025.2
- Part：`xc7k160tffg676-2`
- 综合：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 实现策略：`Performance_Explore`
- 目标频率：95、100、110、120、130 MHz
- ILA：关闭

## 速度榜

速度榜按每条路线满足 `WNS >= 0` 且 `DSP=0` 的最高目标频率排序。

| 排名 | 路线 | 最高通过频率 | WNS(ns) | LUT | FF | DSP | 结论 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 549 | 0 | 通过 |
| 2 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 549 | 0 | 通过 |
| 3 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 549 | 0 | 通过 |
| - | `speed_v6_official_sample` | 未通过 95 MHz | -0.162 | 1704 | 549 | 0 | 未进入通过榜 |

## 效率榜

效率榜按 `MHz / LUT` 排序，只统计 `WNS >= 0` 且 `DSP=0` 的结果。

| 排名 | 路线 | 目标频率 | WNS(ns) | LUT | FF | MHz/LUT | MHz/(LUT+FF) |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 549 | 0.152047 | 0.092593 |
| 2 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 549 | 0.146232 | 0.090403 |
| 3 | `speed_v7c_c91_shift_sub` | 120 MHz | 0.518 | 853 | 549 | 0.140680 | 0.085592 |
| 4 | `speed_v7b_c91_shift_add` | 120 MHz | 0.525 | 873 | 549 | 0.137457 | 0.084388 |
| 5 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 549 | 0.131846 | 0.084691 |

## 结论

- 若只看速度，`speed_v7b_c91_shift_add`、`speed_v7c_c91_shift_sub`、`speed_v7_q7_narrow_mul` 都达到 130 MHz。
- 若同频下优先看资源效率，`speed_v7c_c91_shift_sub` 最优：130 MHz、LUT 855、DSP 0。
- 若优先考虑语义通用性和风险，`speed_v7_q7_narrow_mul` 仍是最稳的上板路线；它同样达到 130 MHz，但 LUT 比专用常数路线更高。
- `speed_v6_official_sample` 在 `max_dsp=0` 后 LUT 增加，95 MHz 已不满足时序，不建议作为最终速度路线。
- 榜单全部为关闭 ILA 的 post-route 结果；带 ILA 版本只用于上板抓波形，不用于正式资源效率排名。

完整数据见：

- `route_a_matrix.csv`
- `speed_leaderboard.csv`
- `efficiency_leaderboard.csv`
