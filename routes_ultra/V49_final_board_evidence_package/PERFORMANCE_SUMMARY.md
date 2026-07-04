# 性能汇总

## 当前可展示排序

| 类别 | 路线 | 状态 | `cnt_test` | 频率 | 理论时间 | WNS | DSP |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 最快已上板 | V45 | 已上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 0 |
| 稳定回退 | V42/V34 | 已上板 | 88 | 300 MHz | 0.293 us | +0.056 ns | 0 |
| 稳定化尝试 | V44 | 未上板 | 88 | 300 MHz | 0.293 us | +0.069 ns | 0 |
| Core1 计算分工证明 | V33 | 未上板 | 135 | 300 MHz | 0.450 us | +0.034 ns | 0 |
| 最快单核 | V31 | 未上板 | 169 | 300 MHz | 0.563 us | +0.181 ns | 0 |
| 低风险已上板备选 | V22b | 已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 0 |

## V45 结果

V45 正式化了 Stage2 wait reduce，得到 `cnt_test=85`。no-ILA 实现 timing-clean，WNS `+0.091 ns`，LUT/FF/DSP 为 2228/1619/0。实物上板 ILA 验证通过，16 个输出全部匹配 `FFT_output.coe`。

## V43 高频结论

V43 保持 `cnt_test=88` 不变，只拉高 PLL 频率。结论是不能直接替代 V45/V42：

- 300 MHz：timing clean。
- 320 MHz：bitstream generated，但 setup timing failed。
- 333.333 MHz：bitstream generated，但 setup timing failed。
- 350 MHz：bitstream generated，但 setup timing failed。
- 340/360 MHz：整数 PLL 配置中 VCO 超出范围。

详细见 `results/v43_freq_sweep.csv`。

## V44 稳定化结论

V44 最优为 `retiming_try`，WNS `+0.069 ns`，相对 V42 提升 `+0.013 ns`，但未超过 V45，也没有达到 `+0.100 ns` 的稳定替代目标。详细见 `results/v44_timing_compare.csv`。
