# Core1 等待分析

## V45 等待

| 等待位置 | 等待内容 | 等待的 shared RAM 值 | 安全边界 |
| --- | --- | --- | --- |
| Stage2 前 | Core1 等待 Core0 生成 Stage1 下半支路 | `RAM10/RAM11/RAM14/RAM15` | `CORE1_WAIT_STAGE2_NOP=68` |
| Stage3 前 | Core1 等待 Core0 生成 Stage2 `(4,6,W0)` 相关输入 | `RAM8/RAM9/RAM12/RAM13` | `CORE1_WAIT_STAGE3_NOP=23` |
| addr15 前 | Core1 等待 Core0 最后一批 verify 写回完成 | Core0 addr2/10/6/14 写回 | `final_addr15_delay=9` |

## V46 迁移后的等待

V46 让 Core1 迁移 Stage1 的两个下半支路：

- `(1,5,W1)` 下半支路产生 `RAM10/RAM11`。
- `(3,7,W3)` 下半支路产生 `RAM14/RAM15`。

Core0 只把原始输入通过 `RAM20..27` 提前转交给 Core1。扫描结果：

| 参数 | 最优安全值 | 说明 |
| --- | ---: | --- |
| `CORE1_WAIT_STAGE1_RAW_NOP` | 12 | Core1 最早安全读取 `RAM20..27` |
| `CORE1_WAIT_STAGE2_NOP` | 0 | Core1 自己已经生成 `RAM10/11/14/15` |
| `CORE1_WAIT_STAGE3_NOP` | 0 | Core1 可以先写后半输出，但 addr15 必须延迟 |
| `final_addr15_delay` | 21 | 保证 addr15 晚于 Core0 addr14 |

## 理论收益与实际结果

理论上，V46 消除了 V45 的 68 个 Stage2 前等待 NOP，并把 4 个 `MUL` 从 Core0 移到 Core1。实际结果没有继续降低 `cnt_test`，原因是：

1. Core0 仍负责前半输出链，最后一批 `addr2/10/6/14` 在 cycle 110..112 写回。
2. Core1 若不延迟 addr15，会在 cycle 92..108 之间提前写 addr15，造成假停表。
3. 为保证 addr15 是最后一次可信写回，`final_addr15_delay` 必须增加到 21。
4. 合法最优点因此回到 `cnt_test=85`，没有超过 V45。

结论：最小 Stage1 迁移是合规可行的，但不构成有效优化。
