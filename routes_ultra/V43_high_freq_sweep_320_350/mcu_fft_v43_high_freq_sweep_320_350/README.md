# V43：V34/V42 高频扫频路线

V43 从 V42 复制而来，功能 RTL、双 MCU 指令流、`cnt_test=88` 口径保持不变。本路线只探索板级 PLL 输出频率和 Vivado 实现余量，用于判断 V34/V42 这条已经上板验证的基线是否还能直接通过提高时钟获得更快时间。

硬性约束：

- 仍然是 32 位 ARM-like MCU 架构。
- 不引入 FFT 专用计算单元、蝶形流水线、DMA、协处理器或专用 FFT 指令。
- 官方资源统计使用 no-ILA bitstream。
- `SYNTH_MAX_DSP=0`，DSP 使用必须为 0。
- 官方样例 + 20 组随机输入必须保持 PASS。

运行方式：

```powershell
cd routes_ultra\V43_high_freq_sweep_320_350\mcu_fft_v43_high_freq_sweep_320_350
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\run_freq_sweep.py --vivado D:\vivado\2025.2\Vivado\bin\vivado.bat
```

结果文件：

- `results/freq_sweep.csv`：频点、WNS/TNS/WHS/资源、理论时间和结论。
- `HIGH_FREQ_SWEEP_REPORT.md`：中文扫频报告。
- `results/freq_*/vivado_board/`：每个可实现频点的 Vivado timing/utilization/DRC/methodology 报告。

注意：340 MHz 和 360 MHz 对 50 MHz 输入时钟的 7 Series PLLE2 整数倍频方案可能超过合法 VCO 范围。脚本会把这类频点记录为 PLL 范围阻塞，而不是伪造实现成绩。
