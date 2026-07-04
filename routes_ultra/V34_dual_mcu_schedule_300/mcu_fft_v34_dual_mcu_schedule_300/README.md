# V34 双 MCU 调度压缩

V34 从 V33 复制而来，不改变计算分工，只把 Core1 Stage2 之后进入 Stage3 的等待从 70 个 NOP 压到 23 个 NOP。

关键结果：

- 官方样例 + 20 组随机输入 PASS。
- `cnt_test=88`，300 MHz 理论时间约 0.293 us。
- verify trace 中 16 次输出全部完成，addr15 是最后一次写入。
- 300 MHz 内部 PLL 时序通过，WNS +0.056 ns。
- LUT 2228，FF 1615，DSP 0，BRAM 0。
- no-ILA bitstream 已生成。

复现：

```powershell
cd routes_ultra\V34_dual_mcu_schedule_300\mcu_fft_v34_dual_mcu_schedule_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

详细说明见 `ROUTE_NOTES.md`。
