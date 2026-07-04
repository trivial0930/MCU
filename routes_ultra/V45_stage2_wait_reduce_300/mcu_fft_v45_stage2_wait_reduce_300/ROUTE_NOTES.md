# V45 路线记录：Stage2 Wait Reduce

## 来源

V45 从已经验证过的 V38 复制并正式化。V38 的核心内容是压缩 Core1 Stage2 开始前的等待，并通过最终 addr15 写回延迟保证 `cnt_test` 停表后不会遗漏后续 verify 写回。因此 V45 不是新增专用硬件，而是把这一优化整理成独立路线、文档和上板证据。

## 关键思想

V34/V42 已经把 Stage3 等待压缩到 23，使 `cnt_test=88`。继续降低 cycle 的瓶颈在 Core1 Stage2 开始前等待 Core0 写入中间值的时间。V45 扫描 `CORE1_WAIT_STAGE2_NOP`，并同时扫描最终 addr15 写回延迟，避免出现 addr15 过早写回导致计数提前停表的假成绩。

## 扫描结论

| 项目 | 结果 |
| --- | --- |
| 扫描 stage2 wait 范围 | 55..80 |
| 最小安全 stage2 wait | 68 |
| 最优 final addr15 delay | 9 |
| `cnt_test` | 85 |
| `verify_we` 写回次数 | 16 |
| 最后写回地址 | 15 |
| 官方样例 + 20 随机 | PASS |
| no-ILA WNS | +0.091 ns |
| DSP | 0 |
| 上板状态 | PASS |

## 上板结论

V45 已完成 no-ILA 下载、ILA 调试抓波、CSV 比对和最终 no-ILA 重新下载。板上 ILA 观测到 16 次 `verify_we` 写回，`verify_addr` 覆盖 0..15，输出与 `FFT_output.coe` 完全一致，最终 `cnt_test=85`。

## 后续是否继续 V46

V45 已经达到当前最快已上板成绩。V46 若继续推进，需要改 Core0/Core1 的 Stage1 分工，验证风险明显高于 V45。建议在答辩前保持 V45 作为主路线，V42 作为回退路线；只有在时间充足时才继续 V46。

## 合规边界

- Core0/Core1 仍是完整 MCU。
- 两个 core 都执行普通 32-bit ARM-like 指令 ROM。
- 没有新增 FFT engine、butterfly unit、DMA、coprocessor。
- 没有新增 BFY/FFT_STAGE/CMUL/CADD/CSUB 等专用指令。
- shared RAM 只做普通存储。
- verify RAM 仍由普通 STR 写入。
- `cnt_test` 仍是全系统 wall-clock 计数。
