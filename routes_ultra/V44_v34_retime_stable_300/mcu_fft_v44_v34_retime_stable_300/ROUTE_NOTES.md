# V44 路线记录：V34/V42 稳定化实现

## 定位

V43 已经证明：在不改逻辑的前提下，直接把 V42 拉到 320 MHz 以上会产生 setup 违例。因此 V44 回到 300 MHz，尝试通过实现策略提高 WNS 余量。

## 保持不变的部分

- `cnt_test=88`。
- 双 MCU 协同计算流程。
- `instr_fft8.mem` / `instr_core1.mem` 指令流。
- `FFT_input.mem` / `FFT_output.coe` 官方样例口径。
- no-ILA 官方资源统计。
- DSP=0。

## 本轮尝试

`scripts/run_v44_stability_sweep.py` 会运行多个实现策略：

| 变体 | 目标 |
| --- | --- |
| `postroute_physopt` | 复现 V37/V38 使用过的 post-route phys_opt 加强策略 |
| `netdelay_high` | 优先降低网络延迟，观察跨模块长线是否改善 |
| `retiming_try` | 在保持功能口径不变的前提下尝试综合 retiming 相关选项 |

## 判定

V44 只有在以下条件同时满足时才算有效稳定化结果：

1. 官方样例 + 20 组随机输入 PASS。
2. no-ILA bitstream 生成成功。
3. WNS/TNS、WHS/THS 均满足。
4. DSP=0。
5. `cnt_test` 不从 88 变慢。

若最佳 WNS 未达到 `+0.100 ns`，V44 会记录为“已尝试但未替代 V42”的稳定化实验。
