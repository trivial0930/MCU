# V38：Stage2 等待压缩与最终写回对齐

V38 从已上板验证的 V34 复制而来，把 `CORE1_WAIT_STAGE2_NOP` 从 80 降到 68，并只延后 Core1 最后一次 addr15 写回 9 个 NOP，使停表点重新对齐真正最后输出。

关键结果：

- 官方样例 + 20 组随机输入 PASS。
- `cnt_test=85`，300 MHz 理论时间约 0.283 us。
- no-ILA 300 MHz timing clean，WNS `+0.091 ns`。
- LUT 2228，FF 1619，DSP 0，BRAM 0。
- DRC 0 Error，仅 CFGBVS/CONFIG_VOLTAGE warning。
- 当前尚未上板，推荐下一步先做 V38 no-ILA 下载，再做 ILA 抓波。

复现：

```powershell
cd routes_ultra\V38_dual_mcu_stage2_wait_reduce_300\mcu_fft_v38_dual_mcu_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v38_stable_no_ila.tcl
```

详细说明见 `ROUTE_NOTES.md`。
