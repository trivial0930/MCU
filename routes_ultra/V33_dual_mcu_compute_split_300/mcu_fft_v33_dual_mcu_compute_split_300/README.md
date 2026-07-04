# V33 双 MCU 中间计算拆分

V33 从 V30 继续开发，跳过 V32。它保留两个完整 MCU，并把 Stage2 的 `(5,7,W2)` 从 Core0 移到 Core1 执行，证明 Core1 不只是写输出，而是真实参与 FFT 中间计算。

关键结果：

- 官方样例 + 20 组随机输入 PASS。
- `cnt_test=135`，300 MHz 理论时间约 0.450 us。
- 300 MHz 内部 PLL 时序通过，WNS +0.034 ns。
- LUT 2228，FF 1616，DSP 0，BRAM 0。
- no-ILA bitstream 已生成。

复现：

```powershell
cd routes_ultra\V33_dual_mcu_compute_split_300\mcu_fft_v33_dual_mcu_compute_split_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

详细说明见 `ROUTE_NOTES.md` 和 `results/core_timeline.md`。
