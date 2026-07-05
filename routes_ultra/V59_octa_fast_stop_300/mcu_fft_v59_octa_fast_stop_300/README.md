# V59_octa_fast_stop_300

V59 是当前最快且已上板验证的 Ultra 路线。它从 V58 的八核 pair-fold balanced 程序继续，只改进停表口径，不改变计算程序，不新增专用硬件或专用指令。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 来源路线 | `V58_octa_pairfold_balanced_300` |
| 核数 | 8 个完整 MCU core |
| 目标频率 | 300 MHz |
| `cnt_test` | 49 |
| 理论时间 | 0.163 us |
| 官方样例 + 20 随机 | PASS |
| no-ILA WNS/TNS | +0.095 ns / 0.000 ns |
| no-ILA WHS/THS | +0.074 ns / 0.000 ns |
| no-ILA LUT/FF/DSP/BRAM | 8677 / 6451 / 0 / 0 |
| 上板状态 | PASS |
| fast-stop 证明 | PASS，ILA 证明不是提前停表 |

## 设计说明

- 8 个 core 均保留 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 每个 core 负责一个 FFT 输出地址，并通过普通 `LDR/ADD/SUB/MUL/STR` 指令完成计算和 verify 写回。
- V59 沿用 V58 的输出计算程序，指令总数仍为 340。
- V59 的新增点是将停表信号改为同拍 `owner_done_next` 判断，去掉 V58 停表寄存后一拍的保守延迟。
- fast-stop 仍要求 8 个 owner core 均完成两次普通 verify `STR` 写回，不能少写、不能跳过 addr15。

## 上板证据

V59 已完成以下板上验证：

- no-ILA bitstream 可下载到 `xc7k160t_0`，最终板卡已回刷 no-ILA 版本。
- ILA 调试 bitstream 已实现并下载，ILA timing clean。
- ILA 触发条件为 `fast_stop_pulse_dbg == 1`。
- 首次 fast-stop 样本中，verify 写回总数为 16，地址 0..15 全覆盖。
- 首次 fast-stop 样本中，`verify_done_mask_next=0xffff`、`owner_seen=0xff`、`owner_done_next=0xff`。
- 输出值与 `results/expected_fft_output.txt` 完全一致。

关键文件：

- `board_validation/BOARD_VALIDATION.md`
- `board_validation/FAST_STOP_PROOF.md`
- `board_validation/v59_ila_fast_stop_capture.csv`
- `board_validation/v59_hw_compare.csv`
- `board_validation/v59_fast_stop_proof.csv`
- `board_validation/v59_hw_compare_status.txt`

## 常用命令

功能回归：

```powershell
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

no-ILA Vivado：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v59_no_ila.tcl -tclargs 300
```

上板验证：

```powershell
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v59_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v59_ila_fast_stop.tcl
py board_validation\compare_v59_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
```

## 展示建议

课堂展示优先使用 V59。讲解时先说明它是八个完整 MCU 的普通指令并行，再展示 `OCTA_MCU_COMPLIANCE_REPORT.md` 和 `board_validation/FAST_STOP_PROOF.md`，最后展示 ILA CSV/比较结果，避免被误解为专用加速器或提前停表。
