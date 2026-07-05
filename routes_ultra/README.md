# routes_ultra：300 MHz 极限优化路线

本目录保存 MCU FFT 在目标板卡 `xc7k160tffg676-2` 上的 300 MHz 极限优化路线。正式速度统计均使用 no-ILA bitstream、`flatten_hierarchy=none`、`max_dsp=0`，并以官方样例 + 20 组随机回归为基础。

## 最新结论

| 项目 | 路线 | 结果 |
| --- | --- | --- |
| 当前最快已实现 bitstream | `V60_component_owner_300` | `cnt_test=38`，300 MHz 理论时间 `0.127 us`，WNS `+0.014 ns`，DSP 0，尚未上板 |
| 当前最快已上板路线 | `V59_octa_fast_stop_300` | `cnt_test=49`，300 MHz 理论时间 `0.163 us`，WNS `+0.095 ns`，ILA fast-stop 证明 PASS |
| 稳定回退路线 | `V54_octa_output_owner_300` | `cnt_test=59`，已上板 |
| 低资源双核备份 | `V45_stage2_wait_reduce_300` | `cnt_test=85`，已上板 |

V60 是当前速度第一的实现候选；V59 是当前最适合课堂展示的已上板主线。

## 速度榜

| 排名 | 路线 | 状态 | `cnt_test` | MCU 频率 | 理论时间 | WNS | LUT | FF | DSP |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | V60_component_owner_300 | PASS，bitstream 已生成，尚未上板 | 38 | 300 MHz | 0.127 us | +0.014 ns | 16970 | 13203 | 0 |
| 2 | V59_octa_fast_stop_300 | PASS，已上板，fast-stop 证明通过 | 49 | 300 MHz | 0.163 us | +0.095 ns | 8677 | 6451 | 0 |
| 3 | V58_octa_pairfold_balanced_300 | PASS，功能候选 | 50 | 300 MHz | 0.167 us | - | - | - | 0 |
| 4 | V57_octa_memory_bank_pairfold_300 | PASS，功能候选 | 52 | 300 MHz | 0.173 us | - | - | - | 0 |
| 5 | V56_octa_bucketed_output_owner_300 | PASS，功能候选 | 54 | 300 MHz | 0.180 us | - | - | - | 0 |
| 6 | V54_octa_output_owner_300 | PASS，已上板 | 59 | 300 MHz | 0.197 us | +0.095 ns | 8733 | 6476 | 0 |
| 7 | V53_quad_output_owner_300 | PASS，bitstream 已生成 | 72 | 300 MHz | 0.240 us | +0.089 ns | 5002 | 3718 | 0 |
| 8 | V45_stage2_wait_reduce_300 | PASS，已上板 | 85 | 300 MHz | 0.283 us | +0.091 ns | 2228 | 1619 | 0 |
| 9 | V42_v34_board_verified_300 | PASS，已上板 | 88 | 300 MHz | 0.293 us | +0.056 ns | 2228 | 1615 | 0 |

完整 CSV 见 `results/ultra_summary.csv`。

## V60 说明

V60 使用 16 个完整 MCU core 做 real/imag component-owner 拆分：

- Core0 到 Core7 分别计算 `real(X0)` 到 `real(X7)`。
- Core8 到 Core15 分别计算 `imag(X0)` 到 `imag(X7)`。
- 每个 core 仍执行普通 32-bit 指令 ROM。
- 每个 verify 地址由对应 owner core 通过普通 `STR` 写入。
- 无 FFT engine、butterfly unit、DMA、coprocessor 或专用 FFT opcode。

入口：

- `V60_component_owner_300/mcu_fft_v60_component_owner_300/README.md`
- `V60_component_owner_300/mcu_fft_v60_component_owner_300/ROUTE_NOTES.md`
- `V60_component_owner_300/mcu_fft_v60_component_owner_300/COMPLIANCE_REPORT.md`
- `V60_component_owner_300/mcu_fft_v60_component_owner_300/results/v60_v65_priority.md`

## 常用命令

V60 功能回归：

```powershell
cd routes_ultra\V60_component_owner_300\mcu_fft_v60_component_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V60 300 MHz no-ILA Vivado：

```powershell
cd routes_ultra\V60_component_owner_300\mcu_fft_v60_component_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v60_no_ila.tcl -tclargs 300
```

V59 上板和 ILA fast-stop 证明：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v59_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v59_ila_fast_stop.tcl
py board_validation\compare_v59_ila_capture.py
```

## Bitstream 位置

```text
D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v59_octa_fast_stop_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v59_octa_fast_stop_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_stable/mcu_fft_board.runs/impl_1/board_top.bit
```
