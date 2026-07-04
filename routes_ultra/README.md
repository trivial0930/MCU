# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频路线。当前已经不再停留在单纯调 PLL 的频点试探，而是完成了面向 300 MHz 的流水化、前递和通用乘法器优化。

统一口径：

- 目标器件：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- MCU 工作时钟：由 `PLLE2_BASE` 在 `board_top.v` 中生成
- 综合层级：`flatten_hierarchy=none`
- DSP 限制：`max_dsp=0`
- 正式资源/时序统计：关闭 ILA
- DRC：当前均为 0 Error，仅保留与原项目一致的 `CFGBVS/CONFIG_VOLTAGE` warning

注意：Vivado 状态文件中的 `target_period_ns=20.000` 是输入 50 MHz 时钟约束，不代表 MCU 工作频率。判断路线频率必须看 PLL 参数和 timing report 中 `clkout_raw` 的 `Requirement`。

## 路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V10 | `V10_width_reduce/mcu_fft_v10_width_reduce` | 25 bit 寄存器堆和 ALU 窄化 | 150 MHz 未过时序，作为失败基线 |
| V11 | `V11_2stage_core/mcu_fft_v11_2stage_core` | 增加取指寄存器边界 | 200 MHz 未过时序，作为失败基线 |
| V12 | `V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300` | 早期两周期 MUL 尝试 | 300 MHz 未过时序，作为失败基线 |
| V13 | `V13_addr_decode_slim/mcu_fft_v13_addr_decode_slim` | 窄地址译码、IF/ID 边界、25 bit 数据通路、CMP 快路径 | 150 MHz timing-clean |
| V19 | `V19_pipeline_300/mcu_fft_v19_pipeline_300` | 发射/执行/写回流水，MUL 顺序移加，RAW 停顿，WB 前递 | 300 MHz timing-clean，余量较稳 |
| V20 | `V20_forward_300/mcu_fft_v20_forward_300` | 在 V19 基础上增加 ALU/MOVI EX 前递，减少停顿 | 速度优于 V19，但时序余量极薄 |
| V21 | `V21_forward_stable_300/mcu_fft_v21_forward_stable_300` | 拆分 EX forward 和 RAW hazard 判定逻辑 | 保持 V20 的 `cnt_test=197`，WNS 提升到 +0.031 ns |
| V22a | `V22_fast_mul_300/mcu_fft_v22_fast_mul_300` | 通用 Q7 MUL 改为 radix-4，每拍处理 2 bit | `cnt_test=181`，300 MHz timing-clean |
| V22b | `V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300` | 通用 Q7 MUL 改为每拍处理 4 bit，2 拍完成 | 当前最快且已上板验证的 300 MHz 路线 |
| V24 | `V24_load_forward_300/mcu_fft_v24_load_forward_300` | 基于 V22b 尝试 test_ROM LDR 前递 | 功能 PASS，但 `cnt_test` 不降且 WNS=-0.005 ns，不推荐 |

## 当前速度榜

| 排名 | 路线 | 回归 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V22b_fast_mul2_300 | 官方样例 + 20 组随机 PASS，已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |
| 2 | V22_fast_mul_300 | 官方样例 + 20 组随机 PASS | 181 | 300 MHz | 0.603 us | +0.089 ns | 1012 | 675 | 0 |
| 3 | V21_forward_stable_300 | 官方样例 + 20 组随机 PASS | 197 | 300 MHz | 0.657 us | +0.031 ns | 973 | 675 | 0 |
| 4 | V20_forward_300 | 官方样例 + 20 组随机 PASS | 197 | 300 MHz | 0.657 us | +0.004 ns | 989 | 675 | 0 |
| 5 | V19_pipeline_300 | 官方样例 + 20 组随机 PASS | 204 | 300 MHz | 0.680 us | +0.121 ns | 860 | 675 | 0 |
| 6 | V13_addr_decode_slim | 官方样例 + 20 组随机 PASS | 157 | 150 MHz | 1.047 us | +0.198 ns | 874 | 462 | 0 |
| - | V24_load_forward_300 | 官方样例 + 20 组随机 PASS | 173 | 300 MHz | 0.577 us | -0.005 ns | 1106 | 681 | 0 |
| - | V10_width_reduce | 官方样例 + 20 组随机 PASS | 157 | 150 MHz | 1.047 us | -0.664 ns | 904 | 448 | 0 |
| - | V11_2stage_core | 官方样例 + 20 组随机 PASS | 157 | 200 MHz | 0.785 us | -1.319 ns | 902 | 481 | 0 |
| - | V12_alu_pipe_300 | 官方样例 + 20 组随机 PASS | 161 | 300 MHz | 0.537 us | -4.099 ns | 1139 | 484 | 0 |

## 推荐使用

- 要展示“当前最快 300 MHz 成绩”：优先使用 `V22b_fast_mul2_300`，该路线已完成实物上板验证，`cnt_test=173`，按 300 MHz 推算为 `0.577 us`，WNS `+0.122 ns`。
- 要展示“稳健保底路线”：仍可保留 `V19_pipeline_300`。
- V20 已被 V21/V22/V22b 超过，不再建议作为最终主线；V21 的价值是证明 forward 拆分能提升时序余量。
- V23 纯汇编调度暂未单独落地：当前 MCU 在 `mul_busy` 期间全局停发，单靠调度无法隐藏乘法等待，真正有效的方向是 V22 系列的通用 MUL 周期优化。
- V24 已验证为负优化：现有汇编没有紧邻 `LDR -> use` hazard，load forwarding 没有降低 `cnt_test`，同时让 WNS 变为负值，不建议合并。

## 常用命令

本地回归：

```powershell
cd routes_ultra\V22b_fast_mul2_300\mcu_fft_v22b_fast_mul2_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

无 ILA Vivado 实现：

```powershell
cd routes_ultra\V22b_fast_mul2_300\mcu_fft_v22b_fast_mul2_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

硬件链路检测：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source routes_ultra\vivado\detect_hw.tcl
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v20_forward_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v21_forward_stable_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v22_fast_mul_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v22b_fast_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v24_load_forward_300/mcu_fft_board.runs/impl_1/board_top.bit  # timing fail, do not use as final
```

## 上板验证

V22b 已完成实物上板验证，详见 `V22b_fast_mul2_300/board_validation/BOARD_VALIDATION.md`。验证结果：

- ILA 触发 `verify_we=1` 后捕获 16 次输出写回。
- 写回地址 0 到 15 全覆盖。
- 写回数据全部匹配 `FFT_output.coe`。
- 最终 `done=1`，`cnt_test=173`。
- 抓波后已重新下载无 ILA 正式 bitstream，`ilas_after_no_ila_program=0`。
