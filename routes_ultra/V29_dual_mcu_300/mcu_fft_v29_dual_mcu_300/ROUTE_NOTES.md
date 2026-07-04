# V29 路线记录：双完整 MCU Phase 1

## 目标

搭建双完整 MCU 核的第一版可验证工程，先保证功能等价和 300 MHz 可实现，再继续推进真正的双核任务划分。

## 当前实现

| 模块 | 状态 |
| --- | --- |
| Core0 | 完整 MCU，运行原 FFT 程序 |
| Core1 | 完整 MCU，运行 `mem/instr_idle.mem` 中的 HALT 程序 |
| Core0 instr/data RAM | 独立 |
| Core1 instr/data RAM | 独立 |
| test_ROM 仲裁 | 尚未实现，Core1 当前不读 test_ROM |
| verify_RAM 仲裁 | 尚未实现，Core1 当前不写 verify_RAM |
| shared_data_ram | 尚未实现 |
| 全局 done | `done_core0 && done_core1` |
| 全局 cnt | start/stop pulse OR，当前行为等价 Core0 |

## 合规说明

- 两个实例都使用完整 `mcu_core`。
- Core1 执行普通指令 ROM，不是硬件 engine。
- 没有 FFT/蝶形/复数乘法/DMA/协处理器模块。
- DSP=0。

## 验证结果

| 项目 | 结果 |
| --- | ---: |
| 官方样例 + 20 随机 | PASS |
| `cnt_test` | 173 |
| 300 MHz timing | PASS |
| WNS/TNS | +0.003 ns / 0.000 ns |
| LUT/FF/DSP | 1679 / 915 / 0 |

## 下一阶段建议

1. 新增 `shared_data_ram`，只做普通读写存储，不参与计算。
2. 新增 test_ROM 固定优先级仲裁，只仲裁访问。
3. 新增 verify_RAM 固定优先级仲裁，只仲裁写回。
4. 先拆成 Core0 前半段、Core1 后半段的生产者/消费者程序。
5. 用同步 flag 等待中间结果，确认官方样例 PASS 后再跑 20 随机。
6. 先以 200/250 MHz 收敛为目标，再冲 300 MHz。

当前 V29 只建议作为后续架构开发起点，不建议作为展示最快路线。
