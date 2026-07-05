# V60 上板验证报告

验证时间：2026-07-05  
路线：`V60_component_owner_300/mcu_fft_v60_component_owner_300`  
目标器件：`xc7k160tffg676-2`  
开发板识别：`xc7k160t_0`

## 1. 无 ILA 最终版下载

bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300/mcu_fft_board.runs/impl_1/board_top.bit
```

下载结果：

```text
program_status=ok
device=xc7k160t_0
ilas_after_no_ila_program=0
```

该版本是正式测速和验收推荐版本。

## 2. ILA 证明版实现

ILA bitstream：

```text
D:/vivado_work/routes_ultra/mcu_fft_v60_component_owner_300_ila/mcu_fft_board.runs/impl_1/board_top.bit
```

ILA probes：

- `test_vector_in`
- `verify_vector_out_all`
- `verify_we_all`
- `verify_addr_all`
- `cnt_test`
- `done`
- `verify_done_mask`
- `verify_done_mask_next`
- `fast_stop_pulse_dbg`

ILA 版本实现结果：

| 项目 | 结果 |
| --- | ---: |
| WNS | +0.007 ns |
| TNS | 0.000 ns |
| WHS | +0.013 ns |
| THS | 0.000 ns |
| LUT | 19126 |
| FF | 17060 |
| DSP | 0 |
| BRAM | 12 |

DRC 只有 `dbg_hub/ILA` 相关 warning，无 error。

## 3. ILA 抓取结果

抓取脚本：`board_validation/capture_v60_ila_fast_stop.tcl`  
比对脚本：`board_validation/compare_v60_ila_capture.py`  
抓取文件：`board_validation/v60_ila_fast_stop_capture.csv`

比对摘要：

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
verify_done_mask_q_at_first_fast_stop=0xffff
verify_done_mask_next_at_first_fast_stop=0xffff
fast_stop_not_early=PASS
compare_status=PASS
overall_status=PASS
```

解释：

- sample 23：偶数地址写回，`verify_we_all=0x5555`。
- sample 31：奇数地址写回，`verify_we_all=0xaaaa`，其中包括最后地址 15。
- sample 32：`fast_stop_pulse_dbg=1`，此时 16 个地址已全部写完，`verify_done_mask_q/next` 均为 `0xffff`。
- sample 33：`done=1`，`cnt_test` 稳定为 38。

因此 V60 没有提前停表。正式计分仍采用 `cnt_test=38`。

## 4. 最终状态

验证完成后，板子已重新下载无 ILA 最终版：

```text
program_status=ok
ilas_after_no_ila_program=0
```

结论：V60 上板验证 PASS，可作为当前最快主线用于验收展示。
