# V19_pipeline_300

V19 是第一条真正达到 300 MHz post-route timing clean 的 Ultra 路线，也是当前建议优先上板验证的 300 MHz 稳定版本。

## 主要改动

- MCU 工作时钟由 50 MHz 输入经 PLL 提升到 300 MHz。
- 核心改为发射、执行、写回流水结构。
- `MUL` 改为顺序移加，避免单周期 LUT 乘法成为 300 MHz 关键路径。
- 增加 RAW 冒险停顿和 WB 前递。
- 保持 `max_dsp=0`，不使用 DSP。

## 当前结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| 仿真 `cnt_test` | 204 |
| 板上 ILA 实测周期数 | 204 |
| MCU 频率 | 300 MHz |
| 按 300 MHz 推算耗时 | 0.680 us |
| 无 ILA WNS | +0.121 ns |
| 无 ILA LUT | 860 |
| 无 ILA FF | 675 |
| 无 ILA DSP | 0 |
| 无 ILA BRAM | 0 |

## 上板验证

2026-07-04 已完成 V19 上板和 ILA 验证：

- Vivado 识别设备：`xc7k160t_0`
- 下载 ILA 调试版 bitstream 成功，启动状态 `HIGH`
- ILA 抓到 `done=1`
- ILA 抓到最终 `cnt_test=0x000cc=204`
- ILA 抓到 16 次 `verify_we=1` 写回
- 16 个硬件写回值与 `results/verify_output.txt` 逐项一致

注意：当前板上已经实测到的是运行周期数和输出正确性；`0.680 us` 是根据 `204 cycles / 300 MHz` 推算得到的执行时间，尚未使用示波器或逻辑分析仪直接测量 start-to-done 脉宽。

详细记录见 [BOARD_VALIDATION.md](./board_validation/BOARD_VALIDATION.md)。

## 命令

```powershell
cd routes_ultra\V19_pipeline_300\mcu_fft_v19_pipeline_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

无 ILA bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300/mcu_fft_board.runs/impl_1/board_top.bit
```

ILA 调试版 bitstream 和探针文件：

```text
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v19_pipeline_300_ila/mcu_fft_board.runs/impl_1/board_top.ltx
```
