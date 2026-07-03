# 资料目录说明

`materials/` 用来集中保存课程资料、官方样例和板卡信息。路线工程中的 `mem/` 已经复制了 FFT 相关样例，日常仿真和 Vivado 初始化优先使用各路线自己的 `mem/` 文件；本目录主要作为来源留档和交叉核对。

## 课程与板卡资料

| 文件 | 来源名称 | 用途 |
| --- | --- | --- |
| `source_docs/digital_circuit_mcu.pptx` | 数字电路实验 MCU 课件 | 理解 MCU 实验要求、接口约束和验收目标。 |
| `source_docs/k7edaeval_pin_map.xlsx` | K7EDAEVAL_PIN 定义 | 核对 `CLK_50M`、`KEY1`、`LED1` 到 `LED8` 的板卡引脚。 |
| `source_docs/mcu_fft_speed_v5_followup_plan.pdf` | MCU_FFT_speed_v5_followup_plan | 路线 A 后续优化的来源说明。 |
| `source_docs/mcu_fft_official_compat_vivado_guide.pdf` | MCU_FFT_official_compat_vivado_guide | 官方样例兼容、Vivado 和上板调试参考。 |

## 官方测试样例

| 文件 | 用途 |
| --- | --- |
| `test_samples/test_data_sample_2026.zip` | 课程提供的原始样例压缩包。 |
| `test_samples/extracted/FFT_input.coe` | 官方 FFT 输入样例。 |
| `test_samples/extracted/FFT_output.coe` | 官方 FFT 期望输出。 |
| `test_samples/extracted/gen_test_data.m` | 官方 MATLAB 样例生成脚本。 |
| `test_samples/extracted/sort_input.coe` | 官方 sort 输入样例，当前 FFT 路线不使用。 |
| `test_samples/extracted/sort_output.coe` | 官方 sort 期望输出，当前 FFT 路线不使用。 |

## 与路线工程的关系

- `speed_v6` 之后的路线使用官方 FFT 样例布局。
- 各路线工程的 `mem/FFT_input.coe`、`mem/FFT_output.coe` 来自本目录官方样例。
- 回归脚本会把 `FFT_input.coe` 转换为仿真可读的 `FFT_input.mem`。
- 上板 ROM 默认读取路线工程内的 `mem/FFT_input.mem`，不要直接引用 `materials/` 下的文件。

## 核对建议

如果怀疑样例或输出格式不一致，按顺序检查：

1. `materials/test_samples/extracted/FFT_input.coe`
2. 路线工程中的 `mem/FFT_input.coe`
3. 路线工程生成的 `mem/FFT_input.mem`
4. `results/expected_fft_output.txt`
5. testbench 或 ILA 观察到的 `verify_vector_out`

这样可以区分“官方样例来源问题”“格式转换问题”和“MCU 执行结果问题”。
