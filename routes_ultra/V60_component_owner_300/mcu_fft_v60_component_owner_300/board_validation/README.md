# V60 上板验证流程

本目录用于 V60_component_owner_300 的上板下载和 ILA 可信停表证明。

## 已验证目标

- 无 ILA 版本下载到 xc7k160tffg676-2 开发板。
- ILA 版本触发 `fast_stop_pulse_dbg`，抓取 16 核并行写回总线。
- 比对 ILA 中的 `verify_vector_out_all` 与仿真期望输出。
- 检查 `verify_we_all`、`verify_addr_all`、`verify_done_mask_next`，证明 `fast_stop` 不是提前停表。

## 推荐命令

```powershell
cd C:\Users\戎择辰\OneDrive\文档\数电实验\MCU\routes_ultra\V60_component_owner_300\mcu_fft_v60_component_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\program_v60_no_ila.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\build_v60_ila_bitstream.tcl
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source board_validation\capture_v60_ila_fast_stop.tcl
py board_validation\compare_v60_ila_capture.py
```

ILA 版本的 `board_top` 会在配置后自动保持 reset 一段时间，方便脚本先布好触发条件，然后释放 reset 并捕获 `fast_stop_pulse_dbg`。
