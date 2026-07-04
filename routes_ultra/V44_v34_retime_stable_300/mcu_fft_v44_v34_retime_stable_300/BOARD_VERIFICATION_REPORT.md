# V44 上板状态说明

V44 是从 V42/V34 派生出的 300 MHz 稳定化实现路线，目前不单独声明已经上板。

已上板证据仍来自 V34/V42：

- no-ILA 版本已完成开发板下载。
- ILA 版本已捕获 16 次 `verify_we` 写回。
- 写回地址覆盖 0 到 15，最后可信写回为 addr15。
- `verify_vector_out` 与 `FFT_output.coe` 全部匹配。

V44 的职责是尝试提高 no-ILA 300 MHz 实现余量。若后续选择 V44 作为展示 bitstream，需要再执行一次独立下载和 ILA/LED 或测试平台验证，并把记录补充到本文件。
