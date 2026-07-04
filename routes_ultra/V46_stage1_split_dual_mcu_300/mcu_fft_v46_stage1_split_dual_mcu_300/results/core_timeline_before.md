# V45 迁移前时间线

本表描述 V45 的关键执行关系，作为 V46 的对照。cycle 为仿真 trace 口径，重点用于说明等待和 verify 写回相对顺序。

| cycle_range | Core0 instruction/task | Core1 instruction/task | shared RAM op | verify op | wait/sync reason |
| --- | --- | --- | --- | --- | --- |
| 0..early | 初始化 `R0/R5/R6/R7`，读取官方输入 | 初始化 `R0/R5` 后执行 NOP | Core0 写 Stage1 中间值 | 无 | Core1 等待 Core0 生成 Stage1 下半支路 |
| early..mid | Stage1 `(1,5,W1)`、`(3,7,W3)`、`(0,4,W0)`、`(2,6,W2)` | `CORE1_WAIT_STAGE2_NOP=68` | Core0 写 `RAM10/11/14/15` 等 | 无 | Core1 Stage2 依赖 `RAM10/11/14/15` |
| mid | Stage2 `(4,6,W0)`、`(0,2,W0)`、`(1,3,W2)` | Core1 Stage2 `(5,7,W2)` | Core0/Core1 分别写 Stage2 结果 | 无 | Core1 继续等待 Core0 生成 `RAM8/9/12/13` |
| 114..118 | Core0 前半输出尚未开始 | Core1 Stage3 `(4,5,W0)` | 读 `RAM8/9/10/11` | Core1 写 addr1/9/5/13 | 后半输出先到达 |
| 122..126 | Core0 Stage3 `(0,1,W0)` | Core1 Stage3 `(6,7,W0)` 部分 | 读 `RAM0..3`、`RAM12..15` | Core0 写 addr0/8/4/12；Core1 写 addr3/11/7 | 避免 verify 写回丢失 |
| 134..138 | Core0 Stage3 `(2,3,W0)` | final addr15 延迟 | 读 `RAM4..7` | Core0 写 addr2/10/6/14，Core1 最后写 addr15 | `final_addr15_delay=9` 保证 addr15 最后写 |

V45 合规结果：官方样例 + 20 随机 PASS，`cnt_test=85`，addr15 是最后一次可信 verify 写回。
