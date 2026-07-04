# V46 迁移后时间线

最优合规点：

- `CORE1_WAIT_STAGE1_RAW_NOP=12`
- `CORE1_WAIT_STAGE2_NOP=0`
- `CORE1_WAIT_STAGE3_NOP=0`
- `final_addr15_delay=21`
- `cnt_test=85`

| cycle_range | Core0 instruction/task | Core1 instruction/task | shared RAM op | verify op | wait/sync reason |
| --- | --- | --- | --- | --- | --- |
| early | Core0 读取 `(1,5)`、`(3,7)` 原始输入，计算上半支路 | Core1 初始化后等待 raw handoff | Core0 写 `RAM20..27`、`RAM2/3/6/7` | 无 | Core1 等待普通 shared RAM 原始输入转交 |
| mid | Core0 计算 `(0,4,W0)`、`(2,6,W2)` | Core1 读 `RAM20..27`，计算 `(1,5,W1)`、`(3,7,W3)` 下半支路 | Core1 写 `RAM10/11/14/15` | 无 | Core1 不再等待 Core0 生成下半支路 |
| mid..late | Core0 执行 Stage2 `(4,6)`、`(0,2)`、`(1,3)` | Core1 执行 Stage2 `(5,7,W2)` | 双方写各自 Stage2 结果 | 无 | 无 Stage2 NOP |
| 78..92 | Core0 尚未输出完前半链 | Core1 执行后半 Stage3 | Core1 读 `RAM8..15` | Core1 写 addr1/9/5/13/3/11/7 | addr15 暂不写，避免早停 |
| 98..112 | Core0 执行前半 Stage3 | Core1 final delay | Core0 读 `RAM0..7` | Core0 写 addr0/8/4/12/2/10/6/14 | Core1 等待 Core0 最后写回 |
| 114 | Core0 已完成最后非 addr15 写回 | Core1 写最终 addr15 | 无 | Core1 写 addr15 | 合法停表 |

板级 trace 见 `results/verify_write_trace.csv`。
