# V59 上板验证说明

本目录用于验证 `V59_octa_fast_stop_300`。本阶段不继续探索更高版本，重点是证明当前最快 V59：

- 能下载到开发板。
- no-ILA 正式 bitstream 可作为最终展示版本。
- ILA 调试版本能抓到完整 verify 写回。
- `fast_stop_pulse` 没有提前停表。
- 板上输出与软件期望一致。

## 实际验证结果

| 项目 | 结果 |
| --- | --- |
| 设备识别 | PASS，`xc7k160t_0` |
| no-ILA 下载 | PASS |
| no-ILA 调试核数量 | 0 |
| ILA bitstream 构建 | PASS |
| ILA timing | WNS/TNS = +0.139 / 0.000 ns，WHS/THS = +0.044 / 0.000 ns |
| ILA 捕获 | PASS，触发 `fast_stop_pulse_dbg == 1` |
| verify 写回数 | 16 |
| verify 地址覆盖 | 0..15 全覆盖 |
| 最后一笔写回 | addr15，值 `d874` |
| 输出比对 | PASS |
| fast-stop 证明 | PASS |
| 验证后板卡状态 | 已回刷 no-ILA 正式 bitstream |

## 运行顺序

```powershell
cd routes_ultra\V59_octa_fast_stop_300\mcu_fft_v59_octa_fast_stop_300

# 1. 下载正式 no-ILA bitstream，确认板卡可识别且没有 ILA
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl

# 2. 构建带 ILA 的调试 bitstream
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v59_ila_bitstream.tcl

# 3. 下载 ILA 版并触发 fast_stop_pulse 抓波
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v59_ila_fast_stop.tcl

# 4. 自动比对输出并证明 fast-stop 未提前
py board_validation\compare_v59_ila_capture.py

# 5. 验证结束后重新刷回 no-ILA 正式 bitstream
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v59_no_ila.tcl
```

## 生成文件

| 文件 | 含义 |
| --- | --- |
| `no_ila_program_status.txt` | no-ILA 下载结果，包含设备名和 ILA 数量 |
| `vivado_ila/v59_ila_bitstream_status.txt` | ILA bitstream 构建状态 |
| `vivado_ila/v59_ila_timing_summary.rpt` | ILA 调试版本时序报告 |
| `vivado_ila/v59_ila_utilization.rpt` | ILA 调试版本资源报告 |
| `vivado_ila/v59_ila_drc.rpt` | ILA 调试版本 DRC 报告 |
| `capture_v59_ila_status.txt` | ILA 下载和抓波状态 |
| `v59_ila_fast_stop_capture.csv` | ILA 原始抓波数据 |
| `v59_hw_compare.csv` | 16 个 verify 输出与期望值逐项比对 |
| `v59_fast_stop_proof.csv` | fast-stop 非提前停表证明摘要 |
| `v59_hw_compare_status.txt` | 自动检查结论 |

## fast-stop 证明口径

ILA 调试版额外抓取：

- `verify_vector_out_all[127:0]`
- `verify_we_all[7:0]`
- `verify_addr_all[39:0]`
- `cnt_test[19:0]`
- `verify_done_mask[15:0]`
- `owner_seen_dbg[7:0]`
- `owner_done_dbg[7:0]`
- `fast_stop_pulse_dbg`

触发条件为 `fast_stop_pulse_dbg == 1`。比较脚本要求：

- verify 写回总数为 16。
- verify 地址 0..15 全覆盖。
- 最后一笔写回地址为 15。
- 第一次 `fast_stop_pulse_dbg` 出现时，16 次写回已经全部出现。
- 第一次 `fast_stop_pulse_dbg` 出现时，`verify_done_mask_next=0xffff`。
- 第一次 `fast_stop_pulse_dbg` 出现时，`owner_seen=0xff` 且 `owner_done_next=0xff`。
- 16 个输出与 `results/expected_fft_output.txt` 完全一致。

只有以上条件同时满足，`v59_hw_compare_status.txt` 才会给出 `overall_status=PASS`。

## 本次捕获摘要

```text
write_count=16
unique_addr_count=16
last_write_addr=15
last_write_sample=32
last_write_cnt_test=48
first_fast_stop_sample=32
first_fast_stop_cnt_test=48
verify_we_at_first_fast_stop=0xaa
writes_at_or_before_first_fast_stop=16
unique_addrs_at_or_before_first_fast_stop=16
verify_done_mask_q_at_first_fast_stop=0x55ff
verify_done_mask_next_at_first_fast_stop=0xffff
owner_seen_at_first_fast_stop=0xff
owner_done_q_at_first_fast_stop=0x55
owner_done_next_at_first_fast_stop=0xff
fast_stop_not_early=PASS
compare_status=PASS
overall_status=PASS
```
