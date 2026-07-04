# V45 Core Timeline 摘要

本文件记录 V45 优化前后的关键调度事实，用于说明为什么选择 `stage2_wait=68` 和 `final_addr15_delay=9`。

## V42/V34 基线

| cycle 区间 | Core0 任务 | Core1 任务 | shared RAM / verify | stall/sync 原因 |
| --- | --- | --- | --- | --- |
| 读取输入阶段 | Core0 读取并准备 Stage1 所需输入 | Core1 读取后半部分输入 | test ROM 读口被两个 MCU 正常访问 | 两核按普通 LDR 指令取数 |
| Stage1 前半 | Core0 计算并写入 Core1 后续需要的中间值 | Core1 等待 Stage2 所需中间值稳定 | shared RAM 存储中间值 | Core1 不能过早读取 RAM5/RAM7 |
| Stage2/Stage3 | Core0 继续完成前半输出链 | Core1 参与 `(5,7,W2)` 相关中间计算和后半输出 | shared RAM 只存储，不计算 | 等待值过小会导致 mismatch 或 addr15 非最后写回 |
| verify 写回 | 两核通过普通 STR 写 verify RAM | 两核通过普通 STR 写 verify RAM | 共 16 次 verify 写回 | 必须保证 addr15 是最后一次可信写回 |

## V45 扫描事实

`scripts/sweep_stage2_wait.py` 扫描 `stage2_wait=55..80` 和 `final_addr15_delay=0..16`。结果显示：

- `stage2_wait < 68` 时，会出现 mismatch、verify 写回不足或最后写回不是 addr15。
- `stage2_wait=68` 是最小安全等待值。
- 在 `stage2_wait=68` 下，`final_addr15_delay=9` 可保证 addr15 为最后可信写回。
- 该组合得到 `cnt_test=85`。

## V45 后续建议

V45 已经达到提示词要求的 `cnt_test <= 85`。下一步优先上板验证 V45，而不是立即推进 V46；只有当 V45 板上验证通过后，再考虑把 Core1 更早引入 Stage1 的 V46。
