# V53 四核时间线

下表用于说明 V53 的并行关系。精确 verify 写回以 `verify_writer_trace.csv` 为准。

| cycle_range | Core0 task | Core1 task | Core2 task | Core3 task | shared/verify |
| --- | --- | --- | --- | --- | --- |
| 0-3 | 初始化 RAM/VERIFY/TEST 基址和 Q7 常数 | 初始化 RAM/VERIFY 基址 | 初始化 RAM/VERIFY 基址 | 初始化 RAM/VERIFY 基址 | 无 |
| 4-31 | Stage1 `(1,5,W1)`，写 RAM2/3/10/11 | 等待 Core0 生成 `(5,7,W2)` 所需值 | 等待 Core0 生成 `(1,3,W2)` 所需值 | 等待 Core1 生成 `(5,7,W2)` Stage2 值 | Core0 写 shared RAM |
| 32-59 | Stage1 `(3,7,W3)`，写 RAM6/7/14/15 | 继续等待 | 继续等待 | 继续等待 | Core0 写 shared RAM |
| 60-77 | Stage1 `(0,4,W0)`，写 RAM0/1/8/9 | 继续等待 | 继续等待 | 继续等待 | Core0 写 shared RAM |
| 78-95 | Stage1 `(2,6,W2)`，写 RAM4/5/12/13 | 开始 Stage2 `(5,7,W2)` | 继续等待 | 继续等待 | Core0/Core1 使用 shared RAM |
| 96-107 | Core0 继续 Stage2/Stage3 前置计算 | Stage2 `(5,7,W2)` 完成后等待 Stage3 | 等待 Core0 Stage2 `(1,3,W2)` | Stage3 `(6,7,W0)` 并写 3/11/7/15 | Core3 完成 4 个 verify 写 |
| 108-118 | Core0 Stage3 前置计算 | Stage3 `(4,5,W0)` 并写 1/9/5/13 | 等待 Core0 Stage2 `(1,3,W2)` | HALT 或空闲 | Core1 完成 4 个 verify 写 |
| 119-123 | Stage3 `(0,1,W0)` 末段 | HALT 或空闲 | Stage3 `(2,3,W0)` 并写 2/10/6/14 | HALT 或空闲 | Core2 写 4 个 verify，Core0 写 addr0 |
| 124-126 | 写 8/4/12，`done_mask` 达到 `ffff` | HALT 或空闲 | HALT 或空闲 | HALT 或空闲 | Core0 最后可信写入 addr12，停表 |

说明：addr15 在 cycle 107 已由 Core3 写入，但 V53 不使用 addr15 作为停表条件；只有 16 个地址全部写完后才停止 `cnt_test`。

