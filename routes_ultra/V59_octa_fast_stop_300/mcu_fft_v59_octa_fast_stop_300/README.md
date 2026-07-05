# V59 八核 fast-stop 路线

V59 从 V58 继续推进，是当前最快 no-ILA bitstream 候选。它不改变 FFT 计算算法，不新增硬件加速器，也不新增指令；唯一额外优化是把 owner-complete 停表信号从寄存后一拍改为同拍送入 `cnt_test_unit`。

## 当前结果

| 项目 | 结果 |
| --- | --- |
| 来源路线 | V58 |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 49 |
| 300 MHz 理论时间 | 0.163 us |
| 指令总数 | 340 |
| Vivado 300 MHz no-ILA | bitstream 已生成 |
| WNS/TNS | +0.095 ns / 0.000 ns |
| WHS/THS | +0.074 ns / 0.000 ns |
| LUT/FF/DSP/BRAM | 8677 / 6451 / 0 / 0 |
| DRC | Checks found: 0 |
| 上板状态 | 待上板；V54 仍是最快已上板版本 |

## 关键证据

- `results/regression_summary.txt`：官方样例 + 20 随机全部 PASS，均为 `cnt_test=49`。
- `results/verify_writer_trace.csv`：16 次 verify 写回完整覆盖，最后一次为 Core7 写 addr15。
- `results/opcode_summary.csv`：只使用普通 MCU 指令，DSP=0。
- `results/vivado_board/board_timing_summary.rpt`：300 MHz WNS `+0.095 ns`。
- `results/vivado_board/board_utilization.rpt`：LUT 8677，FF 6451，DSP 0，BRAM 0。
- `results/vivado_board/board_drc.rpt`：Checks found: 0。

## 复现命令

功能回归：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\octa_audit.py
```

300 MHz no-ILA Vivado：

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v59_no_ila.tcl -tclargs 300
```

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v59_octa_fast_stop_300/mcu_fft_board.runs/impl_1/board_top.bit
```
