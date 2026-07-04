# V42：V34 已上板验证最终基线

V42 从已完成实物上板验证的 V34 固化而来，不改变 RTL 行为、不改变指令流、不改变 `cnt_test` 口径。它的定位是当前最快已上板路线和后续所有激进路线的回退基线。

关键结果：

- 工作频率：300 MHz。
- 官方样例 + 20 组随机输入 PASS。
- `cnt_test=88`，理论时间约 0.293 us。
- no-ILA WNS `+0.056 ns`，DSP 0。
- 已完成 ILA 上板验证：16 次 verify 写回全部匹配，addr15 是最后一次可信写回。

复现：

```powershell
cd routes_ultra\V42_v34_board_verified_300\mcu_fft_v42_v34_board_verified_300
py scripts\generate_v42_evidence.py
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

核心材料：

- `BOARD_VERIFICATION_REPORT.md`
- `COMPLIANCE_REPORT.md`
- `results/verify_write_trace.csv`
- `results/core0_disasm.txt`
- `results/core1_disasm.txt`
- `results/opcode_summary.csv`
