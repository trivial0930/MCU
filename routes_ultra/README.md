# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在 K7 目标板 `xc7k160tffg676-2` 上的高频优化路线。正式统计均使用 no-ILA bitstream、`flatten_hierarchy=none`、`max_dsp=0`，并以后实现报告为准。

## 最新结论

- 当前最快已上板路线：`V59_octa_fast_stop_300`，`cnt_test=49`，300 MHz 理论时间 `0.163 us`，no-ILA WNS `+0.095 ns`，DSP 0。
- V59 已完成 ILA fast-stop 证明：首次 `fast_stop_pulse_dbg` 出现时，16 个 verify 地址已经全部可信写入，输出比对 PASS。
- 当前稳定回退路线：`V54_octa_output_owner_300`，`cnt_test=59`，300 MHz 理论时间 `0.197 us`，已完成板上 ILA 捕获和输出比对。
- 当前双核低资源备份：`V45_stage2_wait_reduce_300`，`cnt_test=85`，已上板。

## 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V59_octa_fast_stop_300 | PASS，已上板，fast-stop 证明通过 | 49 | 300 MHz | 0.163 us | +0.095 ns | 8677 | 6451 | 0 |
| 2 | V58_octa_pairfold_balanced_300 | PASS，功能候选 | 50 | 300 MHz | 0.167 us | - | - | - | 0 |
| 3 | V57_octa_memory_bank_pairfold_300 | PASS，功能候选 | 52 | 300 MHz | 0.173 us | - | - | - | 0 |
| 4 | V56_octa_bucketed_output_owner_300 | PASS，功能候选 | 54 | 300 MHz | 0.180 us | - | - | - | 0 |
| 5 | V54_octa_output_owner_300 | PASS，已上板 | 59 | 300 MHz | 0.197 us | +0.095 ns | 8733 | 6476 | 0 |
| 6 | V53_quad_output_owner_300 | PASS，待上板 | 72 | 300 MHz | 0.240 us | +0.089 ns | 5002 | 3718 | 0 |
| 7 | V45_stage2_wait_reduce_300 | PASS，已上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 2228 | 1619 | 0 |
| 8 | V42_v34_board_verified_300 | PASS，已上板证据固化 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2228 | 1615 | 0 |

完整 CSV 见 `results/ultra_summary.csv`。本轮 V56-V59 的局部迭代榜见 `results/v56_v59_iteration_summary.csv`。

## 本轮路线说明

| 路线 | 工程目录 | 主要改动 | 当前结论 |
| --- | --- | --- | --- |
| V56 | `V56_octa_bucketed_output_owner_300/mcu_fft_v56_octa_bucketed_output_owner_300` | 奇数输出核把 `±91` 项按 real/imag bucket 聚合，只保留两次普通 `MUL` | `cnt_test=54` |
| V57 | `V57_octa_memory_bank_pairfold_300/mcu_fft_v57_octa_memory_bank_pairfold_300` | 对 `±91` 的两组输入 pair 做 fold，减少 add/sub | `cnt_test=52` |
| V58 | `V58_octa_pairfold_balanced_300/mcu_fft_v58_octa_pairfold_balanced_300` | 配平 `X3/X5`，去掉额外取负路径 | `cnt_test=50` |
| V59 | `V59_octa_fast_stop_300/mcu_fft_v59_octa_fast_stop_300` | 在 V58 基础上使用同拍 owner-complete 停表，并用 ILA 证明不是提前停表 | `cnt_test=49`，300 MHz timing clean，已上板 |

## V59 常用命令

功能回归：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

300 MHz no-ILA Vivado：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v59_no_ila.tcl -tclargs 300
```

V59 上板和 ILA fast-stop 证明：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v59_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v59_ila_fast_stop.tcl
py board_validation\compare_v59_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v59_octa_fast_stop_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v59_octa_fast_stop_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v53_quad_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit
```
