# 文档入口

本目录保存当前路线 A 调试和上板交接文档。旧的阶段性状态报告已经合并为一份最新指南。

| 文档 | 用途 |
| --- | --- |
| `上板与交接指南.md` | 最新且唯一的上板交接指南：记录目标 part、license、约束修复、bit/ltx、timing/utilization/DRC 摘要和上板步骤。 |

当前本机状态：

- Vivado 2025.2 路径：`D:\vivado\2025.2\Vivado\bin\vivado.bat`
- Icarus Verilog 已安装：`C:\iverilog\bin`
- 功能回归：四条路线均已 PASS
- 目标板卡 part：已按课件实物封装修正为 `xc7k160tffg676-2`
- 推荐路线 `speed_v7_q7_narrow_mul`：综合、实现、DRC、bitstream 均已完成
- 首板调试文件：`board_top_ila.bit` 与 `board_top_ila.ltx` 已生成
- 老师强调项：`flatten_hierarchy=none`、`max_dsp=0` 已写入 Vivado 脚本，最新报告 `DSPs=0`

注意：课件 `materials/source_docs/Lab1.pdf` 写明实验板 FPGA 为 `XC7K160T-2FFG676-I`，Vivado part 为 `xc7k160tffg676-2`。上板前请以实物 FPGA 丝印为准再次确认封装；若不是 FFG676，需要重新核对 XDC。
