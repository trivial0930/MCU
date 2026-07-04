# V53 四核输出归属路线 300MHz

V53 从 `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` 复制并继续优化。目标是在不增加 FFT engine、butterfly_unit、DMA、协处理器或 FFT 专用指令的前提下，使用四个完整 MCU core 执行普通 32-bit ARM-like 指令，将 8 点 FFT 的输出写回任务按 owner 拆分。

## 当前结论

| 项目 | 结果 |
| --- | --- |
| 官方样例 + 20 组随机 | PASS |
| `cnt_test` | 72 |
| 300MHz 理论时间 | 0.240 us |
| 相比 V45 | 85 -> 72，减少 13 cycle |
| no-ILA 300MHz WNS/TNS | +0.089 ns / 0.000 ns |
| no-ILA 300MHz WHS/THS | +0.065 ns / 0.000 ns |
| LUT/FF/DSP/BRAM | 5002 / 3718 / 0 / 0 |
| DRC | 0 Error |
| bitstream | 已生成 |

V53 目前是仓库中最快的 300MHz no-ILA 合规实现路线，但尚未完成实物上板验证。已上板最快路线仍可保留 V45 作为稳妥展示备份。

## 核心设计

- Core0 保留 Stage1/Stage2 主生产链，并负责输出地址 0、4、8、12。
- Core1 计算 Stage2 `(5,7,W2)` 和 Stage3 `(4,5)`，负责输出地址 1、5、9、13。
- Core2 读取 Core0 生成的 Stage2 `(1,3,W2)` 中间值并计算 Stage3 `(2,3)`，负责输出地址 2、6、10、14。
- Core3 读取 Core1 生成的 Stage2 `(5,7,W2)` 中间值并计算 Stage3 `(6,7)`，负责输出地址 3、7、11、15。
- `cnt_test` 使用 `done_mask == 16'hffff` 停表，不依赖 addr15 最后写入，因此不会因为 addr15 提前写入产生假加速。

## 时序收敛修复

最初四核版本的 300MHz post-route WNS 为负，主要瓶颈来自 verify RAM 四写口仲裁和 shared RAM 写地址路径。最终修复如下：

1. `verify_RAM_quad` 改为按输出归属拆分为四个单写口 bank，去掉四 core 同时写同一 16x16 RAM 的深 mux。
2. `shared_data_ram` 保持普通共享存储语义，但 Core2/Core3 在本路线只读 shared RAM，因此在 `mcu_top` 中关闭 Core2/Core3 写口，减少无效写路径。
3. `mcu_core` 的内存 offset 使用 aligned-base 低 8 位为 0 的路线约定，offset 直接来自指令立即数低 8 位；base 高位仍用于选择 DATA/TEST/VERIFY 区域。所有访问仍由普通 `LDR/STR` 指令发起。

## 复现命令

```powershell
cd routes_ultra\V53_quad_output_owner_300\mcu_fft_v53_quad_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026 --core1-wait 68 --core2-wait 108 --core3-wait 92
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v53_no_ila.tcl -tclargs 300
```

## 关键文件

- `ROUTE_NOTES.md`
- `QUAD_MCU_COMPLIANCE_REPORT.md`
- `results/v53_quad_wait_sweep.csv`
- `results/v53_frequency_sweep.csv`
- `results/verify_writer_trace.csv`
- `results/opcode_summary_all.csv`
- `results/vivado_board/board_timing_summary.rpt`
- `results/vivado_board/board_utilization.rpt`
- `results/vivado_board/board_drc.rpt`

