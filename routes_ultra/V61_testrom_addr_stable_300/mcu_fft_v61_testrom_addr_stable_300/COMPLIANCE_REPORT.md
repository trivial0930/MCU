# V61 合规报告

## 结论

V61 保持 16 个完整 MCU core，并通过普通 32-bit ARM-like 指令完成 8 点定点复数 FFT 的 16 个输出分量。它没有新增 FFT 专用硬件、没有新增专用指令，也没有修改 `cnt_test` 的计数口径。

## 架构合规

| 检查项 | V61 状态 |
| --- | --- |
| 完整 MCU core | 16 个，均保留 PC、指令 ROM、decoder、寄存器堆、ALU、load/store、writeback、halt |
| 指令宽度 | 32-bit 指令字 |
| 数据通路 | 32-bit 寄存器和 ALU 数据路径 |
| 输入读取 | 普通 `LDR` 指令访问 test ROM 映射空间 |
| 计算 | 普通 `ADD/SUB/MUL` 指令 |
| verify 写回 | 普通 `STR` 指令 |
| DSP | 0 |
| BRAM | 0 |
| `cnt_test` | 全系统 wall-clock 计数，未改变口径 |

## 禁止项检查

| 禁止项 | 结果 |
| --- | --- |
| FFT engine | 未新增 |
| butterfly unit | 未新增 |
| fft stage unit | 未新增 |
| twiddle engine | 未新增 |
| DMA controller | 未新增 |
| coprocessor | 未新增 |
| BFY/FFT_STAGE/BUTTERFLY/CMUL/CADD/CSUB opcode | 未新增 |
| 固定 FFT 硬件网络 | 未新增 |

扫描证据：

- `results/forbidden_module_scan.txt`: PASS
- `results/forbidden_opcode_scan.txt`: PASS
- `results/octa_audit_summary.txt`: PASS

## V61 改动是否影响合规

V61 的唯一功能相关 RTL 改动位于 `rtl/ext_test_rom_if.v`：

```verilog
assign test_rom_addr = test_offset;
```

该改动只是让 test-ROM 地址输入不再经过 `is_test_rom` 多路选择器。它不增加计算单元，不增加存储搬运单元，不增加 opcode，也不让 test-ROM 直接写 verify RAM。所有输出仍由各 core 的普通指令计算后通过 `STR` 写入 verify RAM。

非 test-ROM 读访问仍然由 `mcu_core.v` 中的原有写回选择保护：

```verilog
wb_wdata <= ex_is_test_rom ? test_rom_read_data : internal_read_data;
```

因此 V61 的 WNS 优化属于控制路径收敛，不属于专用加速。

## 验证记录

| 项目 | 结果 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机 | PASS |
| `cnt_test` | 38 |
| verify 写回次数 | 16 |
| verify 地址覆盖 | 0 到 15 |
| 基础指令集测试 | PASS |
| 300 MHz no-ILA timing | WNS +0.162 ns |
| DRC | 0 checks found |
| Methodology | 0 checks found |
| bitstream | 已生成 |
| 上板 | 尚未执行 |

## 面向验收的回答要点

- V61 不是 FFT 加速器路线，而是多 MCU 并行执行普通指令的路线。
- 每个输出分量由一个完整 MCU core 负责，teacher 可以查看 `mem/instr_core*.mem` 和 `results/core*_disasm.txt`。
- 机器码和反汇编证据在 `mem/` 与 `results/core*_disasm.txt`。
- 普通指令统计在 `results/opcode_summary_all.csv`。
- 禁用专用硬件和专用 opcode 的扫描结果在 `results/forbidden_module_scan.txt` 与 `results/forbidden_opcode_scan.txt`。
- `cnt_test=38` 来自功能回归和硬件计数逻辑，没有因为少写 verify 或提前停表制造假加速。

