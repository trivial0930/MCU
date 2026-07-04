# MCU FFT 实验仓库

本仓库用于电子科技大学英才实验学院数字电路 MCU FFT 项目。目标是在目标板卡 `xc7k160tffg676-2` 上，用普通 MCU 指令完成 8 点定点复数 FFT，并整理可复现的仿真、综合、实现、bitstream 和上板验证材料。

## 最新状态

更新时间：2026-07-05

当前最快 no-ILA 合规实现已经推进到 8 核路线：

| 项目 | 当前推荐 |
| --- | --- |
| 当前最快 no-ILA 合规候选 | `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300` |
| 核心数 | 8 个完整 MCU core |
| 功能回归 | 官方样例 + 20 组随机输入 PASS |
| `cnt_test` | 58 |
| 300 MHz 理论时间 | 0.193 us |
| Vivado 300 MHz no-ILA | WNS/TNS = +0.011 ns / 0.000 ns |
| 资源 | LUT 8851，FF 6519，DSP 0，BRAM 0 |
| DRC | 0 checks found |
| bitstream | `D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit` |
| 上板状态 | 已生成 bitstream，尚未实物验证 |

V45 仍保留为当前最快已上板验证路线：`cnt_test=85`，300 MHz no-ILA timing-clean，实物验证 PASS。V53 是四核中间路线：`cnt_test=72`，已被 V54 超过。

## 合规边界

当前主线坚持以下约束：

- 不新增 FFT engine、butterfly_unit、fft_stage_unit、twiddle_engine、DMA controller 或 coprocessor。
- 不新增 BFY、FFT_STAGE、BUTTERFLY、CMUL、CADD、CSUB 等 FFT/复数/蝶形专用指令。
- 每个 core 都保留完整 MCU 结构，包括 PC、ROM、decoder、寄存器堆、ALU、load/store、writeback 和 halt。
- 所有输入读取、计算和 verify 写回都通过普通 `LDR/ADD/SUB/MUL/STR` 等指令完成。
- DSP 使用量必须为 0。
- `cnt_test` 保持全系统 wall-clock 口径，从有效输入读取到最后可信 verify 写入完成。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `materials/` | 课程资料、板卡资料、官方输入输出样例和原始文档归档 |
| `docs/` | 上板、交接、报告摘要和调试说明 |
| `routesA/` | 路线 A 稳定候选、Vivado 矩阵和 130 MHz 上板资料 |
| `routesB/` | 路线 B 的 B1 到 B4 候选方案和中文说明 |
| `routes_ultra/` | 300 MHz 极限优化路线，当前重点为 V54/V53/V45/V42 |
| `RESULTS.md` | 当前速度榜、效率榜、推荐路线和风险说明 |
| `WINDOWS_CODEX_HANDOFF.md` | Windows + Vivado + Codex 环境继续调试清单 |

## 复现命令

V54 功能回归：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

V54 300 MHz no-ILA 实现：

```powershell
cd routes_ultra\V54_octa_output_owner_300\mcu_fft_v54_octa_output_owner_300
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source vivado\run_v54_no_ila.tcl
```

V45 已上板路线回归：

```powershell
cd routes_ultra\V45_stage2_wait_reduce_300\mcu_fft_v45_stage2_wait_reduce_300
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

## 上板建议

- 如果要展示当前最快理论成绩，优先使用 V54 的 no-ILA bitstream，下一步补实物上板验证。
- 如果要展示已经上板 PASS 的成绩，使用 V45。
- 如果要保守回退，使用已经固化上板证据的 V42/V34 路线。
- 如果老师重点检查“32 位机器码和架构位宽”，同时准备 V36 或 V54 的 opcode/disassembly/合规说明材料。

## 结果入口

- `RESULTS.md`
- `routes_ultra/README.md`
- `routes_ultra/results/ultra_summary.csv`
- `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300/ROUTE_NOTES.md`
- `routes_ultra/V54_octa_output_owner_300/mcu_fft_v54_octa_output_owner_300/OCTA_MCU_COMPLIANCE_REPORT.md`

## 协作约定

- GitHub 远端使用 SSH：`git@github.com:trivial0930/MCU.git`。
- 中文文档统一使用 UTF-8 编码。
- `build/`、`.Xil/`、Vivado 工程缓存、随机临时输出和 bitstream 大文件不提交。
- 提交到 GitHub 的内容优先保留源码、脚本、关键报告、榜单 CSV/Markdown 和可复现实验命令。
