# Materials

This folder collects the course references and test samples needed to debug the
MCU FFT routes on another machine, especially a Windows machine with Vivado.

## Source Documents

| File | Source name | Purpose |
| --- | --- | --- |
| `source_docs/digital_circuit_mcu.pptx` | `数字电路实验_MCU.pptx` | Course MCU experiment slides. |
| `source_docs/k7edaeval_pin_map.xlsx` | `K7EDAEVAL_PIN定义.xlsx` | K7EDAEVAL board pin definitions. |
| `source_docs/mcu_fft_speed_v5_followup_plan.pdf` | `MCU_FFT_speed_v5_followup_plan.pdf` | Follow-up plan used to define route A. |
| `source_docs/mcu_fft_official_compat_vivado_guide.pdf` | `MCU_FFT_official_compat_vivado_guide.pdf` | Vivado/official compatibility reference. |

## Test Samples

| File | Purpose |
| --- | --- |
| `test_samples/test_data_sample_2026.zip` | Original course sample archive. |
| `test_samples/extracted/FFT_input.coe` | Official FFT input sample. |
| `test_samples/extracted/FFT_output.coe` | Official FFT expected output. |
| `test_samples/extracted/gen_test_data.m` | MATLAB generator from the course sample. |
| `test_samples/extracted/sort_input.coe` | Official sort input sample. |
| `test_samples/extracted/sort_output.coe` | Official sort expected output. |

The route projects already copy the FFT sample files into their own `mem/`
folders for reproducible simulation and Vivado initialization.
