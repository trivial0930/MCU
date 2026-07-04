# V46 Stage1 依赖图

## 基线来源

V46 从 `routes_ultra/V45_stage2_wait_reduce_300/mcu_fft_v45_stage2_wait_reduce_300` 复制。V45 中 Core1 等待 Core0 生成 Stage1 下半支路的 `RAM10/RAM11/RAM14/RAM15`，然后执行 Stage2 `(5,7,W2)`。

## Stage1 中间值来源

| Stage1 蝶形 | Stage1 输出 | V45 产生者 | V46 产生者 | 用途 |
| --- | --- | --- | --- | --- |
| `(0,4,W0)` | `RAM0/RAM1` | Core0 `ADD` 后 `STR` | Core0 保留 | Stage2 `(0,2,W0)` |
| `(0,4,W0)` | `RAM8/RAM9` | Core0 `SUB` 后 `STR` | Core0 保留 | Stage2 `(4,6,W0)`，后续 Core1 Stage3 `(4,5)` |
| `(1,5,W1)` | `RAM2/RAM3` | Core0 `ADD` 后 `STR` | Core0 保留 | Stage2 `(1,3,W2)` |
| `(1,5,W1)` | `RAM10/RAM11` | Core0 `SUB/ADD/MUL` 后 `STR` | Core1 迁移 | Core1 Stage2 `(5,7,W2)` |
| `(2,6,W2)` | `RAM4/RAM5` | Core0 `ADD` 后 `STR` | Core0 保留 | Stage2 `(0,2,W0)` |
| `(2,6,W2)` | `RAM12/RAM13` | Core0 `SUB` 后 `STR` | Core0 保留 | Stage2 `(4,6,W0)` |
| `(3,7,W3)` | `RAM6/RAM7` | Core0 `ADD` 后 `STR` | Core0 保留 | Stage2 `(1,3,W2)` |
| `(3,7,W3)` | `RAM14/RAM15` | Core0 `SUB/ADD/MUL` 后 `STR` | Core1 迁移 | Core1 Stage2 `(5,7,W2)` |

## V46 新增 shared RAM 交换值

| 临时地址 | 内容 | 写入者 | 读取者 | 说明 |
| --- | --- | --- | --- | --- |
| `RAM20` | `x1.real` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM21` | `x1.imag` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM22` | `x5.real` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM23` | `x5.imag` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM24` | `x3.real` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM25` | `x3.imag` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM26` | `x7.real` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |
| `RAM27` | `x7.imag` | Core0 | Core1 | 普通 `STR/LDR` 原始输入转交 |

shared RAM 仍只做普通存储，不参与计算。

## Core1 Stage2 输入可用性

V45 中 Core1 Stage2 需要等待 Core0 完成：

- `RAM10/RAM11`：Stage1 `(1,5,W1)` 下半支路，由 Core0 的 `MUL` 结果写入。
- `RAM14/RAM15`：Stage1 `(3,7,W3)` 下半支路，由 Core0 的 `MUL` 结果写入。

V45 sweep 证明 `CORE1_WAIT_STAGE2_NOP=68` 是安全边界。V46 将这四个值改为 Core1 自己通过普通指令产生，因此 `CORE1_WAIT_STAGE2_NOP` 可以降为 0。

## 可迁移与不可迁移项

可迁移：

- `(1,5,W1)` 的下半支路：`RAM10/RAM11`。
- `(3,7,W3)` 的下半支路：`RAM14/RAM15`。

必须保留在 Core0：

- `(1,5,W1)` 的上半支路：`RAM2/RAM3`，用于 Core0 Stage2 `(1,3,W2)`。
- `(3,7,W3)` 的上半支路：`RAM6/RAM7`，用于 Core0 Stage2 `(1,3,W2)`。
- `(0,4,W0)` 和 `(2,6,W2)`，因为它们直接驱动 Core0 的前半输出链。

## 结论

最小迁移是功能可行的：Core1 真实执行 Stage1 普通 `LDR/SUB/ADD/MUL/STR`，并能将 Stage2 wait 降为 0。但由于 addr15 必须延迟到 Core0 的最后一批 verify 写回之后，合法停表点仍为 `cnt_test=85`，没有超过 V45。
