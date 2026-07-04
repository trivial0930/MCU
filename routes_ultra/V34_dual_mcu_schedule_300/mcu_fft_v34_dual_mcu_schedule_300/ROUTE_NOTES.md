# V34 路线记录：双 MCU 调度压缩

## 来源和目标

V34 从 `routes_ultra/V33_dual_mcu_compute_split_300/mcu_fft_v33_dual_mcu_compute_split_300` 复制而来。V33 已经证明 Core1 可以合规参与 Stage2 中间计算，V34 不再改变计算分工，只收紧 Core1 在 Stage2 之后进入 Stage3 的等待窗口。

本路线继续保持 V33 的合规边界：两个完整 MCU、普通指令 ROM、普通 shared RAM、无 FFT 专用硬件、无专用蝶形指令、DSP=0、关闭 ILA 做正式统计。

## 调度分析

V33 中 Core1 的两个等待点为：

| 等待点 | V33 默认 | V34 默认 | 作用 |
| --- | ---: | ---: | --- |
| `CORE1_WAIT_STAGE2_NOP` | 80 | 80 | 等待 Core0 完成 Stage1 中 Core1 所需的 `(5,7)` 输入来源。 |
| `CORE1_WAIT_STAGE3_NOP` | 70 | 23 | 等待 Core0 完成 Stage2 中 Core1 Stage3 需要的 `(4,6)` 相关数据。 |

边界扫描结果显示：

- `stage3_wait=21/22`：verify 写入不足 16 次或 addr15 过早，结果不合格。
- `stage3_wait=23`：16 次 verify 写入全部完成，addr15 为最后一次写入，官方样例 PASS。
- `stage3_wait=0/15`：输出文件在部分情况下可对齐，但 addr15 过早触发停表，后面仍有输出写入，不可作为正式速度。

因此 V34 选择 `CORE1_WAIT_STAGE3_NOP=23`，这是本轮找到的最小安全边界。

## verify 写入时间线

官方样例 trace：

| cycle | addr | 数据 |
| ---: | ---: | --- |
| 122 | 0 | f280 |
| 124 | 8 | e900 |
| 124 | 4 | e080 |
| 126 | 12 | 0b00 |
| 126 | 1 | e80a |
| 128 | 9 | 317c |
| 128 | 5 | 16f6 |
| 130 | 13 | 0c84 |
| 134 | 2 | 1a80 |
| 136 | 10 | 2c00 |
| 136 | 6 | e680 |
| 138 | 14 | 1600 |
| 138 | 3 | fea2 |
| 140 | 11 | 1f8c |
| 140 | 7 | fa5e |
| 142 | 15 | d874 |

`done cycles=144`，`cnt_test=88`。addr15 是最后一次 verify 写入，因此计数口径可信。

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 官方样例 | PASS |
| 20 组随机输入，seed=2026 到 2045 | PASS |
| 实物上板验证 | PASS |
| `cnt_test` | 88 |
| 理论时间，300 MHz | 0.293 us |
| 内部 MCU 时钟 | PLL 由 50 MHz 输入生成 300 MHz |
| WNS/TNS | +0.056 ns / 0.000 ns |
| WHS/THS | +0.085 ns / 0.000 ns |
| LUT/FF | 2228 / 1615 |
| DSP/BRAM | 0 / 0 |
| DRC | 0 Error，仅 CFGBVS/CONFIG_VOLTAGE warning |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit` |

Timing report 中 `clkout_raw` 周期为 3.333 ns、频率为 300.000 MHz；最差 setup path 的 requirement 为 3.333 ns。

## 上板结果

V34 已完成 ILA 抓波验证。板上抓到 16 次 `verify_we` 写回，地址 0 到 15 全覆盖，最后写地址为 15；所有 `verify_vector_out` 均与 `results/expected_fft_output.txt` 匹配。最后写 addr15 当拍 `cnt_test=87`，`done=1` 后最终 `cnt_test=88`。

验证完成后已重新下载 no-ILA 正式 bitstream，确认 `ilas_after_no_ila_program=0`。详细记录见 `board_validation/BOARD_VALIDATION.md`。

## 复现命令

```powershell
cd routes_ultra\V34_dual_mcu_schedule_300\mcu_fft_v34_dual_mcu_schedule_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

## 结论

V34 将 V33 的 `cnt_test=135` 压缩到 `cnt_test=88`，在 300 MHz 下理论时间约 0.293 us。它没有新增硬件计算单元，只是把 Core1 的后半 Stage3 输出更早穿插进 Core0 的前半输出窗口，是当前最快、合规且已上板验证的 Ultra 路线。V35 单核备胎路线本轮暂缓，因为其目标仅为 168/167，收益远低于 V34 主线。
