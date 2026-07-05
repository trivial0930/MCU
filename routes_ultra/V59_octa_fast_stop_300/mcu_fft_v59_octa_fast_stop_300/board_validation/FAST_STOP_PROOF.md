# V59 fast-stop 非提前停表证明

## 问题背景

V59 的 `cnt_test=49` 很快，容易被质疑是不是只要看到某个输出，尤其是 addr15，就提前停表。为避免这个问题，V59 增加了 ILA-only 调试探针，抓取停表同拍的 verify 写回、done mask 和 owner mask，用板上真实波形证明 fast-stop 没有提前。

这些调试探针只在 `ENABLE_ILA` 下存在，不影响 no-ILA 正式 bitstream。

## RTL 停表逻辑

V59 的 fast-stop 不是由单一地址触发，而是由 8 个 owner core 全部完成第二次 verify 写回触发：

```verilog
owner_seen_next = owner_seen_q | verify_we_i;
owner_done_next = owner_done_q | (verify_we_i & owner_seen_q);
verify_complete_pulse_raw = (owner_done_next == 8'hff) && (owner_done_q != 8'hff);
```

含义如下：

- 第一次看到某个 owner core 的 `verify_we`，只表示该 core 完成了第一笔 verify 写回。
- 同一个 owner core 第二次 `verify_we` 出现时，才把该 core 计入 `owner_done_next`。
- 只有 `owner_done_next == 8'hff`，也就是 8 个 owner 全部完成两次 verify 写回，才产生 `fast_stop_pulse`。
- 因此停表条件与“addr15 是否出现”不是同一个条件。

## ILA 捕获口径

ILA 触发条件：

```text
fast_stop_pulse_dbg == 1
```

关键探针：

| 探针 | 用途 |
| --- | --- |
| `verify_we_all[7:0]` | 当拍哪些 core 正在写 verify |
| `verify_addr_all[39:0]` | 每个 core 当前 verify 写地址 |
| `verify_vector_out_all[127:0]` | 每个 core 当前 verify 写数据 |
| `verify_done_mask[15:0]` | 已出现的 verify 地址 mask |
| `owner_seen_dbg[7:0]` | 已出现过第一次 verify 写的 owner |
| `owner_done_dbg[7:0]` | 已完成第二次 verify 写的 owner 寄存值 |
| `fast_stop_pulse_dbg` | V59 实际停表触发脉冲 |

## 板上捕获结果

`compare_v59_ila_capture.py` 对 `v59_ila_fast_stop_capture.csv` 的检查结果：

| 项目 | 数值 |
| --- | --- |
| write_count | 16 |
| unique_addr_count | 16 |
| last_write_addr | 15 |
| last_write_sample | 32 |
| last_write_cnt_test | 48 |
| first_fast_stop_sample | 32 |
| first_fast_stop_cnt_test | 48 |
| verify_we_at_first_fast_stop | 0xaa |
| writes_at_or_before_first_fast_stop | 16 |
| unique_addrs_at_or_before_first_fast_stop | 16 |
| verify_done_mask_q_at_first_fast_stop | 0x55ff |
| verify_done_mask_next_at_first_fast_stop | 0xffff |
| owner_seen_at_first_fast_stop | 0xff |
| owner_done_q_at_first_fast_stop | 0x55 |
| owner_done_next_at_first_fast_stop | 0xff |
| fast_stop_not_early | PASS |
| compare_status | PASS |
| overall_status | PASS |

## 如何解读 q 和 next

首次 fast-stop 的 ILA 样本中，`owner_done_q=0x55`、`verify_done_mask_q=0x55ff` 看起来还不是最终值，这是因为它们是触发边沿前的寄存值。

同一拍 `verify_we=0xaa`，奇数 owner core 写入最后一批输出。RTL 停表实际使用的是组合 next 值：

- `verify_done_mask_next=0xffff`
- `owner_done_next=0xff`

所以 fast-stop 是在最后一批可信写回同拍产生的，不是写回之前提前产生的。

## 输出比对

`v59_hw_compare.csv` 对 16 个地址逐项比对，全部 PASS。最后一笔写回：

| addr | captured | expected | writer_core | sample | result |
| ---: | --- | --- | ---: | ---: | --- |
| 15 | `d874` | `d874` | 7 | 32 | PASS |

因此，V59 的上板结果满足：

- 16 个 verify 输出全部真实写入。
- addr15 是最后可信写入的一部分。
- fast-stop 出现在所有 owner 完成之后。
- 输出数据与期望完全一致。

结论：V59 的 `cnt_test=49` 不是提前停表造成的假加速。
