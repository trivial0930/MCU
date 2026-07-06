# V61 WNS 稳定化记录

## 发现的问题

V60 的 300 MHz no-ILA 版本已经通过实现并上板，但 final WNS 只有 `+0.014 ns`。Vivado 最差 setup path 落在 test-ROM 读路径上：

- Source: `u_mcu_top/g_mcu_core[3].u_mcu_core/ex_op1_reg[9]/C`
- Destination: `u_mcu_top/g_mcu_core[3].u_mcu_core/wb_wdata_reg[10]/D`
- 路径特征：`ex_op1` 地址判断 -> `is_test_rom` -> `test_rom_addr` 选择 -> 组合 test-ROM -> `wb_wdata`

该路径布线占比较高，说明 WNS 接近 0 主要不是算法延迟，而是地址控制信号牵入 ROM 读路径后带来的 routing 风险。

## 采用的修复

V61 将 `rtl/ext_test_rom_if.v` 中的 test-ROM 地址输出从：

```verilog
assign test_rom_addr = is_test_rom ? test_offset : 8'd0;
```

改为：

```verilog
assign test_rom_addr = test_offset;
```

这样 `is_test_rom` 不再驱动 test-ROM 地址选择，减少一条进入 ROM 组合读的控制路径。

## 功能安全性

该改动不会让非 test-ROM 读访问误取测试 ROM 数据，因为 MCU 写回阶段仍使用：

```verilog
wb_wdata <= ex_is_test_rom ? test_rom_read_data : internal_read_data;
```

计数启动也仍由：

```verilog
mem_read && is_test_rom && (test_offset == 8'd128)
```

触发。因此本次修改不改变功能语义，不改变 `cnt_test` 口径。

## V61 结果

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 38 |
| WNS | +0.162 ns |
| TNS | 0.000 ns |
| WHS | +0.043 ns |
| THS | 0.000 ns |
| LUT | 16712 |
| FF | 13140 |
| DSP | 0 |
| BRAM | 0 |

V61 的最差 setup path 已经转移到普通 MCU 乘法累加路径：

- Source: `u_mcu_top/g_mcu_core[4].u_mcu_core/mul_multiplier_reg[0]/C`
- Destination: `u_mcu_top/g_mcu_core[4].u_mcu_core/mul_acc_reg[37]/D`
- Slack: `+0.162 ns`

## 与 V60 对比

| 项目 | V60 | V61 |
| --- | ---: | ---: |
| `cnt_test` | 38 | 38 |
| WNS | +0.014 ns | +0.162 ns |
| WNS 提升 | - | +0.148 ns |
| LUT | 16970 | 16712 |
| FF | 13203 | 13140 |
| DSP | 0 | 0 |

结论：V61 保持 V60 的最快速度，同时显著增加 300 MHz no-ILA 时序余量。V61 已补做 no-ILA 上板下载和 ILA fast-stop 证明，最后也已恢复 no-ILA bitstream，因此可以作为新的最快主展示版本。
