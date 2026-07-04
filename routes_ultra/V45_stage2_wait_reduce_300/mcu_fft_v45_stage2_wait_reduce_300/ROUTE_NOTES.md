# V45 路线记录：Stage2 Wait Reduce

## 来源

V45 从已经验证过的 V38 复制并正式化。V38 的核心内容正是压缩 Core1 Stage2 等待，因此本路线不重新发明实现，而是把它整理成提示词要求的 V45 目录和文档口径。

## 关键思想

V34/V42 已经把 Stage3 等待压到 23，使 `cnt_test=88`。进一步降 cycle 的瓶颈在 Core1 Stage2 开始前等待 Core0 写入所需中间值。V45 扫描 `CORE1_WAIT_STAGE2_NOP`，并同时扫描最终 addr15 写回延迟，确保不会出现“addr15 过早导致 cnt 停表但后续仍有写回”的假成绩。

## 扫描结论

| 项目 | 结果 |
| --- | --- |
| 扫描 stage2 wait 范围 | 55..80 |
| 最小安全 stage2 wait | 68 |
| 最佳 final addr15 delay | 9 |
| `cnt_test` | 85 |
| `verify_we` 写回次数 | 16 |
| 最后写回地址 | 15 |
| 官方样例 + 20 随机 | PASS |
| no-ILA WNS | +0.091 ns |
| DSP | 0 |

## 为什么不继续开 V46

V45 已经达成 `cnt_test <= 85` 的目标，但还没有独立上板。V46 需要更改 Core0/Core1 的 Stage1 分工，复杂度和验证风险都更高；在没有先把 V45 上板验证前，不建议继续推进 V46。

## 合规边界

- Core0/Core1 都仍是完整 MCU。
- 两个 core 都执行普通 32-bit ARM-like 指令 ROM。
- 没有新增 FFT engine、butterfly unit、DMA、coprocessor。
- 没有新增 BFY/FFT_STAGE/CMUL/CADD/CSUB 等专用指令。
- shared RAM 只做普通存储。
- verify RAM 仍由普通 STR 写入。
- `cnt_test` 仍是全系统 wall-clock 计数。
