# 性能汇总

## 当前可展示排序

| 类别 | 路线 | 状态 | `cnt_test` | 频率 | 理论时间 | WNS | DSP |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 最快已上板 | V42/V34 | 已上板 | 88 | 300 MHz | 0.293 us | +0.056 ns | 0 |
| 最快未上板候选 | V45 | 未上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 0 |
| 稳定化尝试 | V44 | 未上板 | 88 | 300 MHz | 0.293 us | +0.069 ns | 0 |

## V43 高频结论

V43 保持 `cnt_test=88` 不变，只拉高 PLL 频率。结论是不能直接替代 V42：

- 300 MHz：timing clean。
- 320 MHz：bitstream generated，但 setup timing failed。
- 333.333 MHz：bitstream generated，但 setup timing failed。
- 350 MHz：bitstream generated，但 setup timing failed。
- 340/360 MHz：整数 PLL 配置下 VCO 超出范围。

详细见 `results/v43_freq_sweep.csv`。

## V44 稳定化结论

V44 最优为 `retiming_try`，WNS `+0.069 ns`，相对 V42 提升 `+0.013 ns`，没有达到 `+0.100 ns` 的稳定替代目标。详细见 `results/v44_timing_compare.csv`。

## V45 结论

V45 正式化了 Stage2 wait reduce，得到 `cnt_test=85`，满足 V45 目标线。但 V45 尚未上板，所以最终实物展示仍以 V42/V34 为准。
