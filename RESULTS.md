# 当前结果速览

更新时间：2026-07-04

## 最终口径

- 目标器件：`xc7k160tffg676-2`
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/速度统计：关闭 ILA
- 上板调试：先使用带 ILA bitstream，确认功能后切换无 ILA bitstream

## 推荐上板路线

```text
routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
```

已生成文件：

| 文件 | 用途 |
| --- | --- |
| `results/vivado_board/board_top_ila.bit` | 首次上板调试 |
| `results/vivado_board/board_top_ila.ltx` | ILA 波形探针 |
| `results/vivado_board/board_top_no_ila.bit` | 正式资源/速度版本 |
| `results/vivado_board/board_utilization_hierarchical_no_ila.rpt` | MCU 层级资源统计 |

## 速度榜

完整文件：`routes/speed_v8_route_a_vivado_matrix/results/speed_leaderboard.csv`

| 排名 | 路线 | 最高通过频率 | WNS(ns) | LUT | FF | DSP |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 549 | 0 |
| 2 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 549 | 0 |
| 3 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 549 | 0 |
| - | `speed_v6_official_sample` | 未通过 95 MHz | -0.162 | 1704 | 549 | 0 |

## 效率榜

完整文件：`routes/speed_v8_route_a_vivado_matrix/results/efficiency_leaderboard.csv`

| 排名 | 路线 | 目标频率 | WNS(ns) | LUT | MHz/LUT |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | `speed_v7c_c91_shift_sub` | 130 MHz | 0.120 | 855 | 0.152047 |
| 2 | `speed_v7b_c91_shift_add` | 130 MHz | 0.178 | 889 | 0.146232 |
| 3 | `speed_v7c_c91_shift_sub` | 120 MHz | 0.518 | 853 | 0.140680 |
| 4 | `speed_v7b_c91_shift_add` | 120 MHz | 0.525 | 873 | 0.137457 |
| 5 | `speed_v7_q7_narrow_mul` | 130 MHz | 0.027 | 986 | 0.131846 |

## 判断建议

- 若只看资源效率，`speed_v7c_c91_shift_sub` 当前最好。
- 若更看重语义通用性和上板风险，优先使用 `speed_v7_q7_narrow_mul`。
- `speed_v6_official_sample` 在 `max_dsp=0` 后 95 MHz 已不满足时序，不建议作为最终速度路线。

更详细说明见 `docs/上板与交接指南.md` 和
`routes/speed_v8_route_a_vivado_matrix/results/leaderboard_summary.md`。
