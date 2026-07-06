# V61 上板验证报告

更新时间：2026-07-05

## 结论

V61 已完成上板验证。正式 no-ILA bitstream 可以下载到 `xc7k160t_0`，ILA 证明版可以触发 `fast_stop_pulse_dbg` 并抓到 16 个 verify 地址的完整写回。比对结果为 PASS，fast-stop 不是提前停表。验证完成后，开发板已恢复为 V61 no-ILA 正式版本。

## 版本信息

| 项目 | 内容 |
| --- | --- |
| 路线 | `V61_testrom_addr_stable_300` |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300/mcu_fft_board.runs/impl_1/board_top.bit` |
| ILA bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300_ila/mcu_fft_board.runs/impl_1/board_top.bit` |
| ILA probes | `D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300_ila/mcu_fft_board.runs/impl_1/debug_nets.ltx` |
| 目标器件 | `xc7k160tffg676-2` |
| 实测硬件设备 | `xc7k160t_0` |
| 工作频率 | 300 MHz |
| `cnt_test` | 38 |

## no-ILA 下载

`program_v61_no_ila.tcl` 已成功执行：

```text
program_status=ok
device=xc7k160t_0
bit_file=D:/vivado_work/routes_ultra/mcu_fft_v61_testrom_addr_stable_300/mcu_fft_board.runs/impl_1/board_top.bit
ilas_after_no_ila_program=0
```

说明正式版本中没有 ILA 调试核，资源和速度统计仍以 no-ILA 版本为准。

## ILA 证明版实现

ILA 证明版 300 MHz timing clean：

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.008 ns |
| TNS | 0.000 ns |
| WHS | +0.048 ns |
| THS | 0.000 ns |
| LUT | 18899 |
| FF | 17070 |
| DSP | 0 |
| BRAM | 12 |

DRC 和 methodology 报告中只出现 dbg_hub/ILA 相关 warning，无 error。正式计分不使用 ILA 版本。

## ILA 捕获

`capture_v61_ila_fast_stop.tcl` 已成功执行：

```text
program_status=ok
device=xc7k160t_0
ila=hw_ila_1
armed_for=fast_stop_pulse_dbg_eq_1
trigger_position=32
capture_status=ok
csv=board_validation/v61_ila_fast_stop_capture.csv
```

## fast-stop 证明

`compare_v61_ila_capture.py` 输出：

```text
write_count=16
unique_addr_count=16
last_write_addr=15
last_write_sample=31
last_write_cnt_test=36
first_fast_stop_sample=32
first_fast_stop_cnt_test=37
first_done_sample=33
first_done_cnt_test=38
verify_we_at_first_fast_stop=0x0000
writes_at_or_before_first_fast_stop=16
unique_addrs_at_or_before_first_fast_stop=16
verify_done_mask_q_at_first_fast_stop=0xffff
verify_done_mask_next_at_first_fast_stop=0xffff
fast_stop_not_early=PASS
compare_status=PASS
overall_status=PASS
```

关键解释：

- 最后一批 verify 写回在 sample 31 完成，最后写回地址是 addr15。
- fast-stop 在 sample 32 出现，晚于所有 16 次 verify 写回。
- fast-stop 当拍 `verify_done_mask_q=0xffff` 且 `verify_done_mask_next=0xffff`。
- `done` 在 sample 33 稳定，`cnt_test=38`，与仿真回归一致。

## 输出比对

16 个 verify 地址全部与期望输出一致：

| 地址 | 状态 |
| ---: | --- |
| 0-15 | PASS |

详细数据见 `v61_hw_compare.csv`。

## 最终板上状态

完成 ILA 抓取后，已再次执行 `program_v61_no_ila.tcl`，最终开发板上运行的是 V61 no-ILA 正式版本，且 `ilas_after_no_ila_program=0`。
