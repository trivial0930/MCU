# V61 上板验证流程

本目录保存 `V61_testrom_addr_stable_300` 的上板下载、ILA fast-stop 证明和比对结果。

## 已完成结果

| 项目 | 结果 |
| --- | --- |
| no-ILA 下载 | PASS |
| no-ILA 下载后 ILA 数量 | 0 |
| ILA 证明版 bitstream | 已生成 |
| ILA 证明版 WNS/TNS | +0.008 ns / 0.000 ns |
| ILA 触发 | `fast_stop_pulse_dbg` |
| verify 写回次数 | 16 |
| 唯一 verify 地址数 | 16 |
| 最后写回地址 | 15 |
| 输出比对 | PASS |
| fast-stop 是否提前 | PASS，未提前 |
| 最终板上状态 | 已恢复 no-ILA |

## 复现命令

```powershell
cd C:\Users\戎择辰\OneDrive\文档\数电实验\MCU\routes_ultra\V61_testrom_addr_stable_300\mcu_fft_v61_testrom_addr_stable_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v61_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v61_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v61_ila_fast_stop.tcl
py board_validation\compare_v61_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v61_no_ila.tcl
```

## 关键文件

- `BOARD_VALIDATION_REPORT.md`
- `no_ila_program_status.txt`
- `capture_v61_ila_status.txt`
- `v61_ila_fast_stop_capture.csv`
- `v61_hw_compare.csv`
- `v61_fast_stop_proof.csv`
- `v61_hw_compare_status.txt`
- `vivado_ila/v61_ila_timing_summary.rpt`
- `vivado_ila/v61_ila_utilization.rpt`
