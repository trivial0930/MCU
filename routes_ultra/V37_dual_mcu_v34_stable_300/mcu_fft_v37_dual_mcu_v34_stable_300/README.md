# V37：V34 稳定化实现路线

V37 从已上板验证的 V34 复制而来，计算分工、指令流和等待参数保持不变，目标不是继续降低 `cnt_test`，而是把 V34 的 88cnt 成绩做成更适合交付和复现的稳定实现版本。

关键目标：

- 保持官方样例 + 20 组随机输入 PASS。
- 保持 `cnt_test=88`，300 MHz 理论时间约 0.293 us。
- 保持两个完整 MCU、普通指令 ROM、普通 shared RAM、DSP 0。
- 通过更稳健的 Vivado 实现策略尝试提高 WNS 余量。

复现：

```powershell
cd routes_ultra\V37_dual_mcu_v34_stable_300\mcu_fft_v37_dual_mcu_v34_stable_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v37_stable_no_ila.tcl
```

详细说明见 `ROUTE_NOTES.md`。
