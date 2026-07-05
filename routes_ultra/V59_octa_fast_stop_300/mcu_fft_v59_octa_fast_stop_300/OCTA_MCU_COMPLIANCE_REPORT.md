# V59 八核 MCU 合规性报告

## 结论

V59 是八个完整 MCU core 的普通指令并行路线，不是 FFT 专用加速器。它符合老师强调的 32-bit ARM-like MCU 微架构要求，并且已经通过功能回归、Vivado no-ILA 实现、上板下载、ILA fast-stop 证明和输出比对。

## 合规边界逐条说明

| 约束 | V59 情况 |
| --- | --- |
| 不新增 FFT engine | 满足，RTL 中没有 FFT engine 模块 |
| 不新增 butterfly_unit | 满足，RTL 中没有 butterfly_unit 模块 |
| 不新增 fft_stage_unit | 满足，RTL 中没有 fft_stage_unit 模块 |
| 不新增 twiddle_engine | 满足，RTL 中没有 twiddle_engine 模块 |
| 不新增 DMA controller | 满足，所有数据搬运由普通 `LDR/STR` 指令完成 |
| 不新增 coprocessor | 满足，没有旁路协处理器接口 |
| 不新增 FFT 专用指令 | 满足，指令集只使用普通算术、访存和控制类 opcode |
| 不把 FFT stage 写成固定硬件网络 | 满足，FFT 计算由各 core 的指令 ROM 驱动 |
| shared RAM 只作为存储 | 满足，shared/verify RAM 不参与组合计算 |
| verify RAM 由普通 STR 写入 | 满足，16 个输出均由各 core 的普通 `STR` 写回 |
| `cnt_test` 是 wall-clock 口径 | 满足，V59 已用 ILA 证明没有提前停表 |
| DSP 必须为 0 | 满足，no-ILA 和 ILA 实现 DSP 均为 0 |

## 八个 core 为什么仍然是 MCU

每个 core 都实例化同一类 `mcu_core`，保留以下结构：

- 程序计数器 PC。
- 指令 ROM。
- 指令译码 decoder。
- 32-bit 寄存器堆。
- ALU 和普通 `ADD/SUB/MUL` 执行路径。
- `LDR/STR` load-store 访存路径。
- writeback 写回路径。
- halt/完成状态。

V59 的并行方式是“输出归属”：每个 MCU core 负责一个 FFT 输出地址，分别运行自己的普通指令程序。它不是把 FFT 蝶形网络硬连线到硬件里，也不是让一个专用模块直接生成 FFT 结果。

## 指令层证据

V59 程序使用普通指令完成计算和写回。关键 opcode 类型包括：

- `MOVI`
- `LDR`
- `STR`
- `ADD`
- `SUB`
- `MUL`
- `HALT`

不存在 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等 FFT、复数或蝶形专用指令。审计脚本和输出文件位于：

- `scripts/octa_audit.py`
- `results/opcode_summary.csv`
- `results/forbidden_opcode_scan.txt`
- `results/forbidden_module_scan.txt`
- `results/octa_audit_summary.txt`

## 资源证据

no-ILA 正式实现：

| 项目 | 数值 |
| --- | ---: |
| 频率 | 300 MHz |
| WNS/TNS | +0.095 ns / 0.000 ns |
| WHS/THS | +0.074 ns / 0.000 ns |
| LUT | 8677 |
| FF | 6451 |
| DSP | 0 |
| BRAM | 0 |

ILA 调试实现用于证明 fast-stop，不作为正式资源排名：

| 项目 | 数值 |
| --- | ---: |
| 频率 | 300 MHz |
| WNS/TNS | +0.139 ns / 0.000 ns |
| WHS/THS | +0.044 ns / 0.000 ns |
| LUT | 10447 |
| FF | 9678 |
| DSP | 0 |
| BRAM Tile | 7 |

ILA 版本的 BRAM/LUT 增量来自调试核，不属于正式 no-ILA 排名资源。

## fast-stop 为什么不是提前停表

V59 的停表条件不是“看见 addr15 就停”，而是检查 8 个 owner core 是否全部完成第二次 verify 写回：

```verilog
owner_seen_next = owner_seen_q | verify_we_i;
owner_done_next = owner_done_q | (verify_we_i & owner_seen_q);
verify_complete_pulse_raw = (owner_done_next == 8'hff) && (owner_done_q != 8'hff);
```

ILA 捕获证明如下：

| 项目 | 捕获值 |
| --- | --- |
| first_fast_stop_sample | 32 |
| verify_we_at_first_fast_stop | 0xaa |
| writes_at_or_before_first_fast_stop | 16 |
| unique_addrs_at_or_before_first_fast_stop | 16 |
| last_write_addr | 15 |
| verify_done_mask_next_at_first_fast_stop | 0xffff |
| owner_seen_at_first_fast_stop | 0xff |
| owner_done_next_at_first_fast_stop | 0xff |
| fast_stop_not_early | PASS |
| output compare | PASS |

这说明 V59 是在最后一批可信 verify 写回同拍停表，而不是提前停表。详细证明见 `board_validation/FAST_STOP_PROOF.md`。

## 可复现命令

```powershell
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v59_no_ila.tcl -tclargs 300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v59_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v59_ila_fast_stop.tcl
py board_validation\compare_v59_ila_capture.py
```
