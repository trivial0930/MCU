# V29_dual_mcu_300

V29 是双完整 MCU 核并行路线的 Phase 1 骨架。当前版本用于验证双核工程外壳，不作为性能路线。

## 当前架构

- Core0：完整 `mcu_core + instr_rom + data_ram`，运行原 V22b FFT 程序。
- Core1：完整 `mcu_core + instr_rom + data_ram`，运行普通 `HALT` 空闲程序。
- 全局 `done = done_core0 && done_core1`。
- 全局 `cnt_test` 的 start/stop 暂用 Core0/Core1 pulse OR 逻辑；当前只有 Core0 产生有效输入读取和 verify 写回。
- 尚未实现 shared_data_ram、test_ROM 仲裁器、verify_RAM 仲裁器和同步 flag。

## 结果

| 项目 | 结果 |
| --- | ---: |
| 回归 | 官方样例 + 20 组随机 PASS |
| `cnt_test` | 173 |
| MCU 频率 | 300 MHz |
| 推算耗时 | 0.577 us |
| WNS | +0.003 ns |
| TNS | 0.000 ns |
| WHS | +0.108 ns |
| THS | 0.000 ns |
| LUT | 1679 |
| FF | 915 |
| DSP | 0 |

## 结论

V29 Phase 1 证明“两个完整 MCU core 同时存在”的工程骨架可以 300 MHz timing-clean，但余量极薄，且当前 Core1 尚未参与 FFT 计算，所以没有速度收益。下一阶段必须实现 shared_data_ram、test_ROM/verify_RAM 仲裁和分阶段同步，再拆分普通指令程序。
