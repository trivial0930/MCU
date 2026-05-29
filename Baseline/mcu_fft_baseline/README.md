# MCU FFT Baseline

This project is a Verilog-2001 baseline for the MCU course design FFT task. It implements a small instruction-driven MCU and runs an 8-point fixed-point complex FFT entirely through assembly instructions.

## Directory

- `rtl/`: synthesizable MCU RTL and simulation instruction ROM.
- `asm/`: FFT assembly and standard instruction test assembly.
- `scripts/`: assembler, fixed-point FFT reference model, test-vector generator, checker, and COE converter.
- `mem/`: generated instruction and test-vector `.mem/.coe` files.
- `tb/`: Verilog testbenches.
- `results/`: generated reference and simulation output files.

## Top-Level Interface

The top module is `rtl/mcu_top.v`.

```verilog
module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [4:0] test_rom_addr,
    input  wire [15:0] test_vector_in,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [19:0] cnt_test,
    output wire done
);
```

External memory mapping:

- `0x1000` to `0x100F`: external `test_ROM`, output signal `test_vector_in`.
- `0x2000` to `0x200F`: external `verify_RAM`, input signal `verify_vector_out`.
- `0x0000` to `0x00FF`: internal data RAM.

`cnt_test` starts when the MCU first reads `test_ROM[0]` and stops after writing `verify_RAM[15]`.

## ISA

Instructions are fixed 32-bit words:

```text
[31:28] opcode
[27:24] rd
[23:20] rs1
[19:16] rs2
[15:0]  imm16
```

Supported instructions:

```text
NOP, ADD, SUB, AND, OR, MOVI, MOVR, LDR, STR,
B, BL, CMP, BEQ, BNE, MUL, HALT
```

`MUL` is a Q15 multiply:

```text
Rd = (Rs1 * Rs2) >>> 15
```

## FFT Format

Input is 8 complex samples stored as 16 signed 16-bit words:

```text
x0_real, x0_imag, x1_real, x1_imag, ..., x7_real, x7_imag
```

Output is also 16 signed 16-bit words:

```text
X0_real, X0_imag, X1_real, X1_imag, ..., X7_real, X7_imag
```

The assembly program uses 8-point radix-2 DIF FFT and writes results back in natural order after bit-reversal reordering.

## Generate Test Vector

```sh
python3 scripts/gen_test_vector.py --seed 0 --out mem/test_vector.mem --coe mem/test_vector.coe
```

## Assemble Programs

FFT program:

```sh
python3 scripts/assembler.py asm/fft8_baseline.asm -o mem/instr_fft8.mem --coe mem/instr_fft8.coe
```

Standard instruction test:

```sh
python3 scripts/assembler.py asm/standard_instruction_test.asm -o mem/instr_standard.mem --coe mem/instr_standard.coe
```

## Run FFT Simulation With Icarus Verilog

```sh
mkdir -p build
iverilog -g2005 -I rtl -I tb -o build/tb_mcu_fft8.vvp \
  tb/tb_mcu_fft8.v \
  rtl/mcu_top.v rtl/mcu_core.v rtl/instr_rom.v rtl/data_ram.v \
  rtl/ext_test_rom_if.v rtl/verify_ram_if.v rtl/cnt_test.v \
  rtl/decoder.v rtl/control_unit.v rtl/reg_file.v rtl/alu.v
vvp build/tb_mcu_fft8.vvp
```

The simulation writes:

```text
results/verify_output.txt
```

## Check FFT Output

```sh
python3 scripts/fft_fixed_ref.py --input mem/test_vector.mem --out results/expected_fft_output.txt
python3 scripts/check_fft_output.py --input mem/test_vector.mem --got results/verify_output.txt
```

Expected result:

```text
Overall: PASS
```

## Run Standard Instruction Test

```sh
mkdir -p build
iverilog -g2005 -I rtl -I tb -o build/tb_standard_instruction.vvp \
  tb/tb_standard_instruction.v \
  rtl/mcu_top.v rtl/mcu_core.v rtl/instr_rom.v rtl/data_ram.v \
  rtl/ext_test_rom_if.v rtl/verify_ram_if.v rtl/cnt_test.v \
  rtl/decoder.v rtl/control_unit.v rtl/reg_file.v rtl/alu.v
vvp build/tb_standard_instruction.vvp +INSTR_MEM=mem/instr_standard.mem
```

## Vivado Notes

- Use `rtl/mcu_top.v` as the top module.
- Connect `test_rom_addr` to the address port of external `test_ROM`.
- Connect external `test_ROM` data output to `test_vector_in`.
- Connect `verify_addr`, `verify_vector_out`, and `verify_we` to external `verify_RAM`.
- Add `test_vector_in`, `verify_vector_out`, `verify_we`, `verify_addr`, and `cnt_test` to ILA.
- Load `mem/test_vector.coe` into `test_ROM`.
- Load `mem/instr_fft8.coe` into instruction ROM or replace `rtl/instr_rom.v` with a Vivado ROM IP initialized by that COE.

## Baseline Limits

- The MCU is intentionally simple and instruction-driven.
- FFT is not implemented as a dedicated hardware FFT core.
- No pipeline, cache, branch prediction, or operating system support is included.
- `MUL` is specialized for Q15 fixed-point multiplication to keep the instruction set compact.
