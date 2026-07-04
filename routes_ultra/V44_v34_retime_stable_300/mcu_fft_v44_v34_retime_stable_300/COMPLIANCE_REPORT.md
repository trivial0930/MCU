# V44 合规说明

V44 继承 V42/V34 的 32 位 ARM-like MCU 架构，不改变 ISA、指令流和完成口径。

合规边界：

- 使用普通 MCU 指令完成 FFT8 数据处理。
- 不新增 FFT 专用指令。
- 不新增 FFT 专用硬件模块、蝶形流水线、DMA 或协处理器。
- no-ILA 官方统计中 `SYNTH_MAX_DSP=0`，DSP 使用应为 0。
- `cnt_test` 目标保持 88。

验证要求：

```powershell
py scripts\run_official_regression.py --random-cases 20 --seed 2026
py scripts\run_v44_stability_sweep.py --vivado D:\vivado\2025.2\Vivado\bin\vivado.bat
```

本路线是否替代 V42，取决于 `results/timing_compare.csv` 和 `V44_STABILITY_REPORT.md` 中的最佳 WNS 是否明显优于 V42。
