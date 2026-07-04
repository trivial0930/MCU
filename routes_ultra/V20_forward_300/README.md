# V20_forward_300

V20 是当前最快的 300 MHz Ultra 路线。它在 V19 的稳定流水结构上增加 EX 前递，减少 ALU/MOVI 结果相关造成的停顿。

## 主要改动

- 保留 V19 的发射、执行、写回流水。
- 保留顺序移加 MUL，继续避免 DSP 和单周期乘法长路径。
- 对快速结果增加 EX 前递：ADD/SUB/AND/OR/MOVI/MOVR/BL。
- LDR 和 MUL 仍保留停顿，避免把存储器和乘法路径拉回关键路径。

## 当前结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 197 |
| MCU 频率 | 300 MHz |
| 理论时间 | 0.657 us |
| WNS | +0.004 ns |
| LUT | 989 |
| FF | 675 |
| DSP | 0 |
| BRAM | 0 |

V20 已经 timing-clean，但 WNS 只有 `+0.004 ns`。它适合展示当前最快成绩；若上板稳定性优先，建议先用 V19。

## 命令

```powershell
cd routes_ultra\V20_forward_300\mcu_fft_v20_forward_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v20_forward_300/mcu_fft_board.runs/impl_1/board_top.bit
```
