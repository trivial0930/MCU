# V19_pipeline_300

V19 是第一条真正达成 300 MHz post-route timing clean 的 Ultra 路线。

## 主要改动

- MCU 工作时钟由 50 MHz 输入 PLL 到 300 MHz。
- 核心改为发射、执行、写回流水。
- `MUL` 改为顺序移加，避免单周期 LUT 乘法成为 300 MHz 关键路径。
- 增加 RAW 冒险停顿和 WB 前递。
- 保持 `max_dsp=0`，不使用 DSP。

## 当前结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 204 |
| MCU 频率 | 300 MHz |
| 理论时间 | 0.680 us |
| WNS | +0.121 ns |
| LUT | 860 |
| FF | 675 |
| DSP | 0 |
| BRAM | 0 |

## 命令

```powershell
cd routes_ultra\V19_pipeline_300\mcu_fft_v19_pipeline_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300/mcu_fft_board.runs/impl_1/board_top.bit
```
