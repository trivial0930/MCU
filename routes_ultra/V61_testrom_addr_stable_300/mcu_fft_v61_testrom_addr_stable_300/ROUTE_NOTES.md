# V61 路线说明

## 1. 路线定位

V61 的目标不是继续降低 `cnt_test`，而是把 V60 已经达到的 `cnt_test=38` 做得更稳。V60 已经完成上板和 ILA fast-stop 证明，但 no-ILA WNS 只有 `+0.014 ns`，离 0 太近。V61 复制 V60 后，针对最差路径做了一个小而明确的 RTL 收敛优化。

最终结果：

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 38 |
| 300 MHz 理论时间 | 0.127 us |
| 官方样例 + 20 随机 | PASS |
| 基础指令集测试 | PASS |
| WNS | +0.162 ns |
| TNS | 0.000 ns |
| WHS | +0.043 ns |
| THS | 0.000 ns |
| LUT | 16712 |
| FF | 13140 |
| DSP | 0 |
| BRAM | 0 |

## 2. 从 V60 继承的结构

V61 保留 V60 的 16 核 real/imag component-owner 分工：

| Core | 输出分量 | verify 地址 |
| ---: | --- | ---: |
| 0 | `real(X0)` | 0 |
| 1 | `real(X1)` | 1 |
| 2 | `real(X2)` | 2 |
| 3 | `real(X3)` | 3 |
| 4 | `real(X4)` | 4 |
| 5 | `real(X5)` | 5 |
| 6 | `real(X6)` | 6 |
| 7 | `real(X7)` | 7 |
| 8 | `imag(X0)` | 8 |
| 9 | `imag(X1)` | 9 |
| 10 | `imag(X2)` | 10 |
| 11 | `imag(X3)` | 11 |
| 12 | `imag(X4)` | 12 |
| 13 | `imag(X5)` | 13 |
| 14 | `imag(X6)` | 14 |
| 15 | `imag(X7)` | 15 |

每个 core 都运行独立的普通 32-bit ARM-like 指令 ROM。偶数分量 core 使用 33 条指令，奇数分量 core 使用 37 条指令，全系统总指令数为 560。计算路径由 `LDR/ADD/SUB/MUL/STR` 组成，没有专用 FFT 指令。

## 3. V60 暴露的问题

V60 的 300 MHz no-ILA 实现虽然 timing clean，但 WNS 只有 `+0.014 ns`。最差路径从 Core3 的 `ex_op1` 相关寄存器出发，经由 test-ROM 地址选择逻辑进入组合 test-ROM，再回到 `wb_wdata`。

这条路径的问题在于：

- `is_test_rom` 既参与数据选择，又参与 test-ROM 地址选择。
- test-ROM 地址选择会牵出 ROM 组合读取路径。
- Vivado 报告中该路径布线延迟占比很高，说明它已经进入比较贴边的 routing 状态。

## 4. V61 实际修改

V61 只修改 [rtl/ext_test_rom_if.v](rtl/ext_test_rom_if.v)：

```verilog
assign test_rom_addr = test_offset;
```

该修改去掉了 test-ROM 地址端口上的 `is_test_rom ? test_offset : 8'd0` 选择器。功能安全性来自两点：

- `wb_wdata` 的 load 数据来源仍由 `ex_is_test_rom` 决定。
- `first_read_pulse` 仍由 `mem_read && is_test_rom && test_offset==128` 触发。

也就是说，非 test-ROM 访问时 test-ROM 地址端口可以变化，但返回数据不会进入 MCU 寄存器，也不会影响计数启动。

## 5. 验证结果

已完成：

- 官方样例 PASS。
- 20 组随机输入 PASS，seed 为 2026 到 2045。
- `cnt_test=38`，与 V60 一致。
- verify 写回 16 次，地址 0 到 15 全覆盖。
- 基础指令集测试 PASS，`cycles=31`。
- `scripts/octa_audit.py` PASS。
- 禁用模块扫描 PASS。
- 禁用 opcode 扫描 PASS。
- 300 MHz no-ILA Vivado synthesis、implementation、DRC、methodology、bitstream 全部完成。

尚未完成：

- V61 尚未下载上板。
- V61 尚未抓 ILA fast-stop 证明。该证明可以沿用 V60 的验证方法，在需要把 V61 替换成正式上板版本时补做。

## 6. Vivado 结果

正式 no-ILA 版本：

| 项目 | 结果 |
| --- | ---: |
| 频率 | 300 MHz |
| WNS | +0.162 ns |
| TNS | 0.000 ns |
| WHS | +0.043 ns |
| THS | 0.000 ns |
| LUT | 16712 |
| FF | 13140 |
| DSP | 0 |
| BRAM | 0 |
| DRC | 0 checks found |
| Methodology | 0 checks found |

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300/mcu_fft_board.runs/impl_1/board_top.bit
```

## 7. 建议

V61 建议作为新的 no-ILA 上板候选版本。若明天验收只需要最稳妥的已证明版本，仍优先使用 V60；若希望降低 WNS 贴边风险，则先给 V61 补一次上板下载和 ILA fast-stop 证明，再把 V61 升为主展示版本。

