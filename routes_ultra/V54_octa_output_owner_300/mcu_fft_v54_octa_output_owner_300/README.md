# V54 八核输出归属路线 300MHz

V54 从 `V53_quad_output_owner_300` 继续推进，把 4 核输出归属拆分扩展为 8 个完整 MCU core。每个 core 独立执行普通 32-bit ARM-like 指令 ROM，并负责一个复数输出 `X0..X7` 的实部和虚部 verify 写回。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 组随机 | PASS |
| `cnt_test` | 59 |
| 300 MHz 理论时间 | 0.197 us |
| 相比 V53 | 72 -> 59，减少 13 cycle |
| 相比 V45 | 85 -> 59，减少 26 cycle |
| no-ILA 300MHz WNS/TNS | +0.095 ns / 0.000 ns |
| no-ILA 300MHz WHS/THS | +0.072 ns / 0.000 ns |
| LUT/FF/DSP/BRAM | 8733 / 6476 / 0 / 0 |
| DRC | Checks found: 0 |
| bitstream | 已生成 |
| 上板状态 | PASS，最终已重新下载 no-ILA 正式版本 |

本次为了降低上板风险，把原来非常贴近 0 的停表路径拆开：先记录每个 owner core 的两次 verify 写回，再把完成脉冲打一拍后送入 `cnt_test_unit`。这样 `cnt_test` 从 58 保守变为 59，但 300MHz no-ILA WNS 从约 +0.011 ns 提升到 +0.095 ns，更适合实物演示。

## 核心设计

- Core0..Core7 分别拥有 `X0..X7`。
- 每个 core 都有自己的 instruction ROM。
- 每个 core 都通过普通 `LDR` 从复制后的 `test_ROM` 读取输入。
- 每个 core 都用普通 `ADD/SUB/MUL` 完成对应输出的计算。
- 每个 core 都通过普通 `STR` 写入对应 verify bank。
- verify RAM 拆成 8 个 owner bank，每个 bank 只接收一个 core 的写入。
- `done_mask` 仍记录 16 个 verify 地址是否被写入，用于仿真和上板证据。
- 正式停表由 8 个 owner 均完成两次 verify 写回后打一拍产生，保持全系统 wall-clock 口径，不依赖某一个地址提前写入。

## 上板验证

已在 `xc7k160t_0` 开发板上完成：

| 项目 | 结果 |
| --- | --- |
| no-ILA 下载 | PASS |
| ILA 调试版下载 | PASS |
| ILA 抓波 | PASS |
| 板上 verify 写回次数 | 16 |
| 覆盖地址 | 0..15 |
| 最后写回地址 | 15 |
| 最后写回时 `cnt_test` | 57 |
| `done` 稳定后 `cnt_test` | 59 |
| 输出比对 | 与 `results/expected_fft_output.txt` 完全一致 |
| 最终板上版本 | no-ILA 正式 bitstream，`ilas_after_no_ila_program=0` |

上板证据文件：

- `board_validation/no_ila_program_status.txt`
- `board_validation/capture_v54_ila_status.txt`
- `board_validation/v54_ila_verify_we_capture.csv`
- `board_validation/v54_hw_compare.csv`
- `board_validation/v54_hw_compare_status.txt`

## 复现命令

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

上板验证：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v54_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v54_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v54_ila_verify_we.tcl
py board_validation\compare_v54_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v54_no_ila.tcl
```

## 关键文件

- `ROUTE_NOTES.md`
- `OCTA_MCU_COMPLIANCE_REPORT.md`
- `results/regression_summary.txt`
- `results/v54_best_summary.txt`
- `results/verify_writer_trace.csv`
- `results/opcode_summary_all.csv`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `results/vivado_board/board_drc.rpt`
- `board_validation/BOARD_VALIDATION.md`
