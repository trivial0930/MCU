# V54 300MHz 上板验证记录

验证日期：2026-07-05

## 验证对象

- 路线：`V54_octa_output_owner_300`
- 工程：`routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300`
- Vivado part：`xc7k160tffg676-2`
- 硬件目标：`localhost:3121/xilinx_tcf/Digilent/210251A08870`
- 识别器件：`xc7k160t_0`
- 板载输入时钟：50 MHz
- MCU 工作时钟：`board_top.v` 内部 PLLE2 生成 300 MHz

## 正式 no-ILA 指标

| 项目 | 结果 |
| --- | ---: |
| `cnt_test` | 59 |
| 300 MHz 理论时间 | 0.197 us |
| WNS | +0.095 ns |
| TNS | 0.000 ns |
| WHS | +0.072 ns |
| THS | 0.000 ns |
| LUT | 8733 |
| FF | 6476 |
| DSP | 0 |
| BRAM | 0 |
| DRC | 0 checks found |

正式 no-ILA bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
```

下载状态见 `no_ila_program_status.txt`。最后一次下载后 `ilas_after_no_ila_program=0`，说明开发板最终停留在无 ILA 正式版本。

## ILA 调试验证

V54 是 8 核并行写回，单路 `verify_we` 会漏掉同周期多 core 写入。因此 ILA 调试版使用宽探针：

- `verify_vector_out_all[127:0]`
- `verify_we_all[7:0]`
- `verify_addr_all[39:0]`
- `cnt_test[19:0]`
- `done`

调试版加入仅在 `ENABLE_ILA` 下生效的上电 reset 延迟，保证脚本有时间 arm ILA，然后自动释放 reset 触发一次完整计算。

## 板上比对结果

| 项目 | 结果 |
| --- | --- |
| ILA 实例 | `hw_ila_1` |
| 触发条件 | `verify_we_all == 8'h55` |
| 抓取状态 | PASS |
| verify 写回次数 | 16 |
| 覆盖地址 | 0..15 |
| 最后写回地址 | 15 |
| 最后写回时 `cnt_test` | 57 |
| `done` 稳定后 `cnt_test` | 59 |
| 输出比对 | 与 `results/expected_fft_output.txt` 完全一致 |
| 总体验证 | PASS |

详细文件：

- `capture_v54_ila_status.txt`
- `v54_ila_verify_we_capture.csv`
- `v54_hw_compare.csv`
- `v54_hw_compare_status.txt`
- `vivado_ila/v54_ila_timing_summary.rpt`
- `vivado_ila/v54_ila_utilization.rpt`

## 操作命令

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v54_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v54_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v54_ila_verify_we.tcl
py board_validation\compare_v54_ila_capture.py
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v54_no_ila.tcl
```

最后一步用于把板子从 ILA 调试版切回正式 no-ILA 版本。
