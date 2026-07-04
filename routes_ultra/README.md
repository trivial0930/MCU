# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频路线。正式统计均使用无 ILA bitstream，综合层级 `flatten_hierarchy=none`，`max_dsp=0`。

统一口径：

- 目标器件：`xc7k160tffg676-2`
- 板载输入时钟：50 MHz
- MCU 工作时钟：由 `board_top.v` 中的 `PLLE2_BASE` 生成
- 正式资源/时序统计：关闭 ILA
- 回归：官方样例 + 20 组随机输入
- `cnt_test`：从第一次有效读取输入，到最后一次 verify 输出写入完成

## 最新结论

- 当前最快路线：`V30_dual_mcu_real_300`，真实双 MCU 输出拆分，`cnt_test=149`，300 MHz，WNS `+0.021 ns`。
- 当前最快单核路线：`V31_single_core_final_tune_300`，`cnt_test=169`，300 MHz，WNS `+0.181 ns`。
- 当前已上板验证主线：`V22b_fast_mul2_300`，`cnt_test=173`，300 MHz，WNS `+0.122 ns`。
- V27a/V27b 虽然把 `cnt_test` 降到 157，但 300 MHz 时序失败，不能作为主线。
- V29 Phase 1 已搭出双完整 MCU 骨架并 300 MHz timing-clean，但 Core1 还未参与 FFT，当前无速度收益。

## 路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V10 | `V10_width_reduce/mcu_fft_v10_width_reduce` | 25 bit 寄存器堆和 ALU 窄化 | 150 MHz 未过时序，失败基线 |
| V11 | `V11_2stage_core/mcu_fft_v11_2stage_core` | 增加取指寄存器边界 | 200 MHz 未过时序，失败基线 |
| V12 | `V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300` | 早期两周期 MUL 尝试 | 300 MHz 未过时序，失败基线 |
| V13 | `V13_addr_decode_slim/mcu_fft_v13_addr_decode_slim` | 窄地址译码、IF/ID 边界、25 bit 数据通路 | 150 MHz timing-clean |
| V19 | `V19_pipeline_300/mcu_fft_v19_pipeline_300` | 发射/执行/写回流水，顺序移加 MUL | 300 MHz timing-clean |
| V20 | `V20_forward_300/mcu_fft_v20_forward_300` | ALU/MOVI EX 前递 | 300 MHz 余量极薄 |
| V21 | `V21_forward_stable_300/mcu_fft_v21_forward_stable_300` | 拆分 forward/hazard 逻辑 | WNS 优于 V20 |
| V22a | `V22_fast_mul_300/mcu_fft_v22_fast_mul_300` | radix-4 通用 Q7 MUL | `cnt_test=181` |
| V22b | `V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300` | 每拍处理 4 bit multiplier | 已上板验证主线 |
| V24 | `V24_load_forward_300/mcu_fft_v24_load_forward_300` | test_ROM LDR 前递 | 功能 PASS，但时序失败 |
| V26 | `V26_scheduled_mul2_300/mcu_fft_v26_scheduled_mul2_300` | 输出基址初始化前移，R14 临时寄存器 | `cnt_test=172`，300 MHz PASS |
| V27a | `V27_mul_explore_300/V27a_mul1_lut_300/mcu_fft_v27a_mul1_lut_300` | 单拍通用 LUT Q7 MUL | 功能 PASS，300 MHz FAIL |
| V27b | `V27_mul_explore_300/V27b_hybrid_mul_300/mcu_fft_v27b_hybrid_mul_300` | 通用 small-constant fast path | 功能 PASS，300 MHz FAIL |
| V28 | `V28_branch_reduce_300/mcu_fft_v28_branch_reduce_300` | branch/HALT/输出开销检查，输出基址前移 | `cnt_test=172`，300 MHz PASS |
| V29 | `V29_dual_mcu_300/mcu_fft_v29_dual_mcu_300` | 双完整 MCU Phase 1 骨架 | 300 MHz PASS，但无加速 |
| V30 | `V30_dual_mcu_real_300/mcu_fft_v30_dual_mcu_real_300` | 真实双 MCU 输出拆分，Core1 写后半 verify 输出 | `cnt_test=149`，300 MHz PASS |
| V31 | `V31_single_core_final_tune_300/mcu_fft_v31_single_core_final_tune_300` | W2 蝶形直接计算 `b.real-a.real`，删除 3 条 counted SUB | `cnt_test=169`，300 MHz PASS |

## 当前速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V30_dual_mcu_real_300 | PASS，未上板 | 149 | 300 MHz | 0.497 us | +0.021 ns | 2076 | 1318 | 0 |
| 2 | V31_single_core_final_tune_300 | PASS，未上板 | 169 | 300 MHz | 0.563 us | +0.181 ns | 1053 | 675 | 0 |
| 3 | V26_scheduled_mul2_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 3 | V28_branch_reduce_300 | PASS，未上板 | 172 | 300 MHz | 0.573 us | +0.067 ns | 1050 | 675 | 0 |
| 5 | V22b_fast_mul2_300 | PASS，已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |
| 6 | V22_fast_mul_300 | PASS | 181 | 300 MHz | 0.603 us | +0.089 ns | 1012 | 675 | 0 |
| 7 | V21_forward_stable_300 | PASS | 197 | 300 MHz | 0.657 us | +0.031 ns | 973 | 675 | 0 |
| 8 | V20_forward_300 | PASS | 197 | 300 MHz | 0.657 us | +0.004 ns | 989 | 675 | 0 |
| 9 | V19_pipeline_300 | PASS | 204 | 300 MHz | 0.680 us | +0.121 ns | 860 | 675 | 0 |
| - | V27b_hybrid_mul_300 | 功能 PASS，时序 FAIL | 157 | 300 MHz | 0.523 us | -1.052 ns | 1361 | 698 | 0 |
| - | V27a_mul1_lut_300 | 功能 PASS，时序 FAIL | 157 | 300 MHz | 0.523 us | -2.199 ns | 1203 | 648 | 0 |
| - | V24_load_forward_300 | 功能 PASS，时序 FAIL | 173 | 300 MHz | 0.577 us | -0.005 ns | 1106 | 681 | 0 |
| - | V29_dual_mcu_300 | Phase 1 骨架 PASS | 173 | 300 MHz | 0.577 us | +0.003 ns | 1679 | 915 | 0 |

## 常用命令

本地回归：

```powershell
cd routes_ultra\V30_dual_mcu_real_300\mcu_fft_v30_dual_mcu_real_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

无 ILA Vivado 实现：

```powershell
cd routes_ultra\V30_dual_mcu_real_300\mcu_fft_v30_dual_mcu_real_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

嵌套路线也可直接运行，例如：

```powershell
cd routes_ultra\V27_mul_explore_300\V27b_hybrid_mul_300\mcu_fft_v27b_hybrid_mul_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\..\vivado\run_no_ila_board_bitstream.tcl
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v22b_fast_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v26_scheduled_mul2_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v28_branch_reduce_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v29_dual_mcu_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v30_dual_mcu_real_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v31_single_core_final_tune_300/mcu_fft_board.runs/impl_1/board_top.bit
```

V27a/V27b 和 V24 会生成 bitstream，但 timing 未通过，不建议作为最终上板版本。
