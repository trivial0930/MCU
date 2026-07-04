# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频优化路线。正式统计均使用 no-ILA bitstream、`flatten_hierarchy=none`、`max_dsp=0`，并以后实现报告为准。

## 最新结论

- 当前最快 no-ILA 合规候选：`V54_octa_output_owner_300`，`cnt_test=58`，300 MHz 理论时间 `0.193 us`，WNS `+0.011 ns`，DSP 0，bitstream 已生成，待上板验证。
- 当前最快已上板路线：`V45_stage2_wait_reduce_300`，`cnt_test=85`，300 MHz no-ILA timing-clean，实物验证 PASS。
- 四核路线：`V53_quad_output_owner_300`，`cnt_test=72`，已被 V54 超过。
- 稳定回退路线：`V42_v34_board_verified_300`，`cnt_test=88`，已固化 V34 上板证据。
- 32-bit 合规展示路线：`V36_arm32_compliance_300`。

## 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V54_octa_output_owner_300 | PASS，待上板 | 58 | 300 MHz | 0.193 us | +0.011 ns | 8851 | 6519 | 0 |
| 2 | V53_quad_output_owner_300 | PASS，待上板 | 72 | 300 MHz | 0.240 us | +0.089 ns | 5002 | 3718 | 0 |
| 3 | V45_stage2_wait_reduce_300 | PASS，已上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 2228 | 1619 | 0 |
| 3 | V46_stage1_split_dual_mcu_300 | PASS，无速度收益 | 85 | 300 MHz | 0.283 us | +0.029 ns | 2231 | 1629 | 0 |
| 5 | V42_v34_board_verified_300 | PASS，已上板证据固化 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2228 | 1615 | 0 |
| 6 | V33_dual_mcu_compute_split_300 | PASS，未上板 | 135 | 300 MHz | 0.450 us | +0.034 ns | 2228 | 1616 | 0 |
| 7 | V30_dual_mcu_real_300 | PASS，未上板 | 149 | 300 MHz | 0.497 us | +0.021 ns | 2076 | 1318 | 0 |
| 8 | V31_single_core_final_tune_300 | PASS，未上板 | 169 | 300 MHz | 0.563 us | +0.181 ns | 1053 | 675 | 0 |
| 8 | V36_arm32_compliance_300 | PASS，合规展示 | 169 | 300 MHz | 0.563 us | +0.157 ns | 1213 | 822 | 0 |
| 10 | V22b_fast_mul2_300 | PASS，已上板 | 173 | 300 MHz | 0.577 us | +0.122 ns | 1053 | 675 | 0 |

完整 CSV 见 `results/ultra_summary.csv`。

## 路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V22b | `V22b_fast_mul2_300/mcu_fft_v22b_fast_mul2_300` | 每拍处理 4 bit multiplier | 已上板低风险保底 |
| V30 | `V30_dual_mcu_real_300/mcu_fft_v30_dual_mcu_real_300` | Core1 写后半 verify 输出 | `cnt_test=149`，旧双核路线 |
| V31 | `V31_single_core_final_tune_300/mcu_fft_v31_single_core_final_tune_300` | 单核 W2 蝶形直接改写 | `cnt_test=169`，最快单核 |
| V33 | `V33_dual_mcu_compute_split_300/mcu_fft_v33_dual_mcu_compute_split_300` | Core1 计算 Stage2 `(5,7,W2)` | `cnt_test=135` |
| V42 | `V42_v34_board_verified_300/mcu_fft_v42_v34_board_verified_300` | 固化 V34 上板证据 | `cnt_test=88`，稳定回退 |
| V45 | `V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` | Stage2 wait reduce + final addr15 delay | `cnt_test=85`，最快已上板 |
| V46 | `V46_stage1_split_dual_mcu_300/mcu_fft_v46_stage1_split_dual_mcu_300` | Core1 迁移 Stage1 下半支路 | `cnt_test=85`，负结果保留 |
| V53 | `V53_quad_output_owner_300/mcu_fft_v53_quad_output_owner_300` | 四核输出归属、verify RAM bank 化 | `cnt_test=72` |
| V54 | `V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300` | 八核输出归属、ROM 复制、verify RAM 8-bank | `cnt_test=58`，当前最快 no-ILA 候选 |

## V54 常用命令

功能回归：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

300 MHz no-ILA Vivado：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v54_no_ila.tcl
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v53_quad_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v42_v34_board_verified_300/mcu_fft_board.runs/impl_1/board_top.bit
```
