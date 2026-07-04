# V54 八核输出归属路线 300MHz

V54 从 `V53_quad_output_owner_300` 继续推进，把 4 核输出归属拆分扩展为 8 个完整 MCU core。每个 core 独立执行普通 32-bit ARM-like 指令 ROM，并负责一个复数输出 `X0..X7` 的实部和虚部 verify 写回。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 组随机 | PASS |
| `cnt_test` | 58 |
| 300 MHz 理论时间 | 0.193 us |
| 相比 V53 | 72 -> 58，减少 14 cycle |
| 相比 V45 | 85 -> 58，减少 27 cycle |
| no-ILA 300MHz WNS/TNS | +0.011 ns / 0.000 ns |
| no-ILA 300MHz WHS/THS | +0.063 ns / 0.000 ns |
| LUT/FF/DSP/BRAM | 8851 / 6519 / 0 / 0 |
| DRC | Checks found: 0 |
| bitstream | 已生成 |
| 上板状态 | 待实物验证 |

## 核心设计

- Core0..Core7 分别拥有 `X0..X7`。
- 每个 core 都有自己的 instruction ROM。
- 每个 core 都通过普通 `LDR` 从复制后的 `test_ROM` 读取输入。
- 每个 core 都用普通 `ADD/SUB/MUL` 完成对应输出的计算。
- 每个 core 都通过普通 `STR` 写入对应 verify bank。
- verify RAM 被拆成 8 个 owner bank，每个 bank 只接受一个 core 的写入，降低多写口 mux 深度。
- `cnt_test` 由全局 `done_mask == 16'hffff` 停表，不依赖某一个地址提前写入。

## 指令级优化

V54 初版 `cnt_test=78`，瓶颈来自奇数输出核重复计算 `×91`。最终版本在每个奇数 core 内复用普通 `MUL` 结果：

- 对每个含 `91/-91` 系数的 pair，只计算一次 `diff_real * 91` 和一次 `diff_imag * 91`。
- 复用 `R14/R15` 中的乘法结果同时更新实部和虚部累加器。
- 没有新增硬件，也没有新增指令。
- 该优化把奇数 core 指令数从 53 降到 49，`cnt_test` 从 78 降到 58。

## 复现命令

功能回归：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

300 MHz no-ILA Vivado：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v54_no_ila.tcl
```

## 关键文件

- `ROUTE_NOTES.md`
- `OCTA_MCU_COMPLIANCE_REPORT.md`
- `results/regression_summary.txt`
- `results/v54_best_summary.txt`
- `results/verify_writer_trace.csv`
- `results/opcode_summary_all.csv`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `results/vivado_board/board_drc.rpt`

## 后续建议

V54 当前是最快 no-ILA 合规候选，下一步建议优先完成实物上板验证。如果上板 PASS，可把主展示路线从 V45 切换到 V54；V45 继续保留为最快已验证回退路线。
