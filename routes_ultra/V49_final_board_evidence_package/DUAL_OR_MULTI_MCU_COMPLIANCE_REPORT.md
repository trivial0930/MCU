# 双 MCU 合规说明

最终已上板路线 V42/V34 是真实双 MCU 路线。

## 两个 core 的结构

Core0 和 Core1 均包含：

- PC
- instruction ROM
- decoder/control
- register file
- ALU
- load/store 路径
- writeback 路径

Core1 不是协处理器，也不是 FFT engine。Core1 执行普通指令 ROM，参与中间计算和 verify 输出写回。

## 存储与写回

- shared RAM 只承担普通存储职责，不进行计算。
- verify RAM 由普通 STR 指令写入。
- `cnt_test` 是全局 wall-clock 计数，从有效输入读取到最后一次可信 verify 写回完成。

## 合规边界

本设计没有新增 butterfly unit、FFT stage unit、twiddle engine、DMA controller 或 coprocessor。双 MCU 的加速来自普通 MCU 指令调度和任务拆分，不来自专用硬件捷径。
