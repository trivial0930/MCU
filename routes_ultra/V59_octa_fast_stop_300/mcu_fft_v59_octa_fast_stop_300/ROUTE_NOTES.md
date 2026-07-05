# V59 路线说明

## 来源

V59 复制自 `routes_ultra/V58_octa_pairfold_balanced_300/mcu_fft_v58_octa_pairfold_balanced_300`。

## 实现内容

- 保留 V58 的八核 output-owner 计算程序。
- 保留四个奇数核 46 条指令、四个偶数核 39 条指令的配平结果。
- 保持每个 core 通过普通 `LDR/ADD/SUB/MUL/STR` 计算自己负责的输出。
- 将 `cnt_test_unit.stop_pulse` 从寄存后一拍的 `verify_complete_pulse_q` 改为同拍的 `verify_complete_pulse_raw`。
- `verify_complete_pulse_raw` 仍由 owner 第二次 verify 写回产生，判据为 8 个 owner core 都完成两次普通 `STR` 写回。

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
| 上板状态 | 已验证 | 未上板 | 待上板 |

## 建议

V59 是当前最快 no-ILA bitstream 候选，建议作为下一次上板验证对象。上板验证时建议沿用 V54 的流程：先下载 no-ILA，确认板卡状态；再生成 ILA 调试版抓取 16 次 verify 写回；最后重新刷回 no-ILA 正式 bitstream。
