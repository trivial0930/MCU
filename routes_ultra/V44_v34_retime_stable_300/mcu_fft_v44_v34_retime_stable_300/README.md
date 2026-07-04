# V44：V34/V42 300 MHz 稳定化路线

V44 从 V42 复制而来，保持 V34/V42 的双 MCU 指令流和 `cnt_test=88` 不变。它的目标不是继续降 cycle，而是在 300 MHz no-ILA 官方统计口径下尝试提高实现余量，判断 V42 这条已上板基线能否更稳。

硬性约束：

- 仍然是 32 位 ARM-like MCU 架构。
- 不引入 FFT 专用硬件、蝶形流水线、DMA、协处理器或专用 FFT 指令。
- 不改变 `cnt_test=88` 的完成口径。
- 官方资源统计使用 no-ILA bitstream。
- `SYNTH_MAX_DSP=0`，DSP 使用必须为 0。
- 官方样例 + 20 组随机输入必须 PASS。

运行方式：

```powershell
cd routes_ultra\V44_v34_retime_stable_300\mcu_fft_v44_v34_retime_stable_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\run_v44_stability_sweep.py --vivado D:\vivado\2025.2\Vivado\bin\vivado.bat
```

结果文件：

- `results/v44_timing_sweep.csv`：不同实现策略的 WNS/TNS/WHS/资源。
- `results/timing_compare.csv`：V42 baseline 与 V44 best after 对比。
- `results/worst_path_before.txt`：V42 基线最差 setup path。
- `results/worst_path_after.txt`：V44 最优实现最差 setup path。
- `V44_STABILITY_REPORT.md`：中文稳定化报告。

说明：V44 当前只做实现稳定化，不代表已经独立上板。实物上板证据仍以 V42/V34 的 ILA 捕获和 no-ILA 下载记录为准。
