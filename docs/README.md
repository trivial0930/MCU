# 文档入口

本目录保存当前路线 A 调试和上板交接文档。建议队友按下面顺序阅读：

| 文档 | 用途 |
| --- | --- |
| `上板完成状态_2026-07-03.md` | 最新状态：记录目标 part、license、约束修复、无 ILA/带 ILA bitstream、timing/utilization/DRC 摘要和上板步骤。 |
| `上板前检查执行记录.md` / `上板前检查执行记录-latest.pdf` | 当前最重要的状态记录：列出已经补齐的上板前步骤、实际命令、PASS 结果，以及仍然阻塞的 Vivado 目标器件项。 |
| `当前工作状态报告.md` / `当前工作状态报告.pdf` | 面向队友的阶段性总报告，适合快速了解已经完成的工作和风险。 |
| `后续操作与上板指南.md` | 从当前仓库继续完成 K7EDAEVAL 最终实现矩阵、bitstream 和 ILA 上板验收的详细步骤。 |

当前本机状态：

- Vivado 2025.2 路径：`D:\vivado\2025.2\Vivado\bin\vivado.bat`
- Icarus Verilog 已安装：`C:\iverilog\bin`
- 功能回归：四条路线均已 PASS
- 替代器件综合冒烟：四条路线均已 PASS
- 目标板卡 part：已按课程引脚表修正为 `xc7k325tffg676-2`
- 推荐路线 `speed_v7_q7_narrow_mul`：综合、实现、DRC、bitstream 均已完成
- 首板调试文件：`board_top_ila.bit` 与 `board_top_ila.ltx` 已生成

注意：旧文档中提到的 `xc7k325tffg900-2` 与当前课程引脚表不匹配。上板前请以实物 FPGA 丝印为准再次确认封装；若不是 FFG676，需要重新核对 XDC。
