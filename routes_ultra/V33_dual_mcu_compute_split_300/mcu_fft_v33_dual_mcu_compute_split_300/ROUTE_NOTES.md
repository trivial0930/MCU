# V33 路线记录：双 MCU 中间计算拆分

## 来源和目标

V33 按照“跳过 V32，直接从 V33 继续”的要求，从 `routes_ultra/V30_dual_mcu_real_300/mcu_fft_v30_dual_mcu_real_300` 复制并继续开发。目标不是增加专用 FFT 硬件，而是让 Core1 从“只写后半 verify 输出”升级为“真实参与 FFT 中间计算”的第二个完整 MCU。

本路线保持以下合规约束：

- Core0/Core1 都是完整 `mcu_core`，均执行普通指令 ROM。
- Core1 的中间计算使用普通 `LDR/STR/ADD/SUB/MUL/MOVI` 指令完成。
- `shared_data_ram` 只作为普通共享数据 RAM，不做蝶形、重排、合并或 FFT stage 计算。
- 未新增 FFT engine、butterfly unit、DMA、协处理器或专用复数指令。
- `cnt_test` 口径未修改，DSP 强制为 0，正式资源统计关闭 ILA。

## 任务划分

| 模块 | 任务 |
| --- | --- |
| Core0 | 读取官方 test ROM，重排 Stage1 计算顺序，优先写出 Core1 需要的中间值；完成 Stage2 中的 `(4,6,W0)`、`(0,2,W0)`、`(1,3,W2)`；完成 Stage3 前半输出。 |
| Core1 | 等待 Stage1/部分 Stage2 数据稳定后，执行 Stage2 `(5,7,W2)`，再执行 Stage3 后半 `(4,5,W0)`、`(6,7,W0)` 并写 verify。 |
| shared_data_ram | 交换 FFT 中间值，地址 0 到 15 对应 8 个复数点的实部/虚部。 |
| verify 输出 | Core0 写前半地址，Core1 写后半地址；addr15 由 Core1 最后写入。 |

Core1 新增的真实计算任务是 Stage2 的 `(5,7,W2)`，这部分原本由 Core0 执行。Core0 因此少做一组 Stage2 蝶形，Core1 在后半输出前把对应中间值写回 RAM，然后继续使用普通 MCU 指令生成后半 verify 数据。

## 关键修改

- `scripts/gen_fft8_official_asm.py`
  - 将 Core0 Stage1 顺序改为 `(1,5,W1)`、`(3,7,W3)`、`(0,4,W0)`、`(2,6,W2)`，提前产出 Core1 需要的数据。
  - Core0 Stage2 删除 `(5,7,W2)`。
  - Core1 新增 Stage2 `(5,7,W2)`，默认 `CORE1_WAIT_STAGE2_NOP=80`、`CORE1_WAIT_STAGE3_NOP=70`。
- `rtl/mcu_core.v`、`rtl/alu.v`、`rtl/reg_file.v`
  - 恢复为 32-bit 数据通路，避免老师检查“32 位机器码和架构位宽”时出现口径问题。
- `rtl/shared_data_ram.v`
  - 保持普通 RAM 语义，深度收敛到本任务实际使用的低地址区域，未引入计算逻辑。
- `tb/tb_mcu_fft8.v`
  - 增加可选 `TRACE_VERIFY` 打印，仅用于调试 verify 写入顺序，默认仿真不受影响。

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机输入，seed=2026 到 2045 | PASS |
| `cnt_test` | 135 |
| 理论时间，300 MHz | 0.450 us |
| 内部 MCU 时钟 | PLL 由 50 MHz 输入生成 300 MHz |
| WNS/TNS | +0.034 ns / 0.000 ns |
| WHS/THS | +0.140 ns / 0.000 ns |
| LUT/FF | 2228 / 1616 |
| DSP/BRAM | 0 / 0 |
| DRC | 0 Error，仅 CFGBVS/CONFIG_VOLTAGE warning |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v33_dual_mcu_compute_split_300/mcu_fft_board.runs/impl_1/board_top.bit` |

## 复现命令

```powershell
cd routes_ultra\V33_dual_mcu_compute_split_300\mcu_fft_v33_dual_mcu_compute_split_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

## 结论

V33 满足提示词中 `cnt_test <= 145` 的目标，并证明 Core1 可以合规参与中间 FFT 计算。不过它仍有明显等待空隙，后续 V34 在不改变计算分工的前提下继续压缩同步等待。
