# V33 Core0/Core1 时间线

本文件用于证明 V33 中 Core1 真实参与 FFT 中间计算，而不是只做输出搬运。周期来自 `TRACE_VERIFY` 调试和指令调度分析；正式回归仍以 `results/route_regression.log` 为准。

| cycle_range | Core0 instruction/task | Core1 instruction/task | shared RAM op | verify op | stall/sync reason |
| --- | --- | --- | --- | --- | --- |
| 0-80 | 初始化寄存器，开始 Stage1 | 初始化后执行 `CORE1_WAIT_STAGE2_NOP=80` | Core0 逐步写 Stage1 中间值 | 无 | Core1 等待 `(5,7)` 所需输入稳定。 |
| 80-120 | Core0 已优先完成 `(1,5,W1)`、`(3,7,W3)`、`(0,4,W0)`、`(2,6,W2)`，并进入 Stage2 | Core1 读取 RAM5/RAM7，执行 Stage2 `(5,7,W2)` | Core1 读 RAM 5/7，随后写回 RAM 5/7 | 无 | 这是 V33 新增的真实中间计算任务。 |
| 120-138 | Core0 执行 Stage3 前半 `(0,1)`、`(2,3)` | Core1 继续等待 `CORE1_WAIT_STAGE3_NOP=70` | Core0/Core1 使用 shared RAM 中不同地址 | Core0 写 addr0/8/4/12/2/10/6/14 | 保证 Core0 生成 Core1 后续 `(4,5)`、`(6,7)` 所需数据。 |
| 174-176 | 已完成前半输出 | Core1 执行 Stage3 `(4,5,W0)` | Core1 读 RAM4/RAM5 | Core1 写 addr1/9/5/13 | Core1 开始写后半 verify。 |
| 186-188 | HALT | Core1 执行 Stage3 `(6,7,W0)` | Core1 读 RAM6/RAM7 | Core1 写 addr3/11/7/15 | addr15 最后写入，触发可信停表。 |
| 191 | HALT | HALT | 无 | `done cycles=191, cnt_test=135` | 官方样例和 20 组随机均 PASS。 |

## verify 写入顺序

```text
verify cycle=122 addr=0
verify cycle=124 addr=8
verify cycle=124 addr=4
verify cycle=126 addr=12
verify cycle=134 addr=2
verify cycle=136 addr=10
verify cycle=136 addr=6
verify cycle=138 addr=14
verify cycle=174 addr=1
verify cycle=174 addr=9
verify cycle=176 addr=5
verify cycle=176 addr=13
verify cycle=186 addr=3
verify cycle=186 addr=11
verify cycle=188 addr=7
verify cycle=188 addr=15
```

## 同步观察

- Core1 的第一个等待点仍然较长，但它是为了避免读到 Core0 尚未写入的 Stage1 数据。
- V33 的主要空隙出现在 `CORE1_WAIT_STAGE3_NOP=70`，V34 正是针对该空隙继续压缩。
- `shared_data_ram` 没有形成硬件计算路径，只承担普通读写交换。
