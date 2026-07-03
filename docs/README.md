# 文档入口

本目录保存当前路线 A 调试和上板交接文档。建议队友按下面顺序阅读：

| 文档 | 用途 |
| --- | --- |
| `上板前检查执行记录.md` / `上板前检查执行记录-latest.pdf` | 当前最重要的状态记录：列出已经补齐的上板前步骤、实际命令、PASS 结果，以及仍然阻塞的 Vivado 目标器件项。 |
| `当前工作状态报告.md` / `当前工作状态报告.pdf` | 面向队友的阶段性总报告，适合快速了解已经完成的工作和风险。 |
| `后续操作与上板指南.md` | 从当前仓库继续完成 K7EDAEVAL 最终实现矩阵、bitstream 和 ILA 上板验收的详细步骤。 |

当前本机状态：

- Vivado 2025.2 路径：`D:\vivado\2025.2\Vivado\bin\vivado.bat`
- Icarus Verilog 已安装：`C:\iverilog\bin`
- 功能回归：四条路线均已 PASS
- 替代器件综合冒烟：四条路线均已 PASS
- 目标板卡 part：`xc7k325tffg900-2` 仍未安装到本机 Vivado device database

因此，正式生成 K7EDAEVAL bitstream 前必须先用管理员权限打开 Vivado 安装器，执行 `Add Design Tools or Devices 2025.2`，补齐 `xc7k325tffg900-2` 所在的 Kintex-7 7K325 器件支持。
