## ============================================================
## Clock
## ============================================================

set_property PACKAGE_PIN <你的时钟管脚> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## PPT中给出的时钟约束，20ns 对应 50MHz
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]


## ============================================================
## Reset Button: KEY1
## ============================================================

set_property PACKAGE_PIN <KEY1管脚> [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]


## ============================================================
## Switches: CODE1-CODE4
## ============================================================

set_property PACKAGE_PIN <CODE1管脚> [get_ports {switch_input[0]}]
set_property PACKAGE_PIN <CODE2管脚> [get_ports {switch_input[1]}]
set_property PACKAGE_PIN <CODE3管脚> [get_ports {switch_input[2]}]
set_property PACKAGE_PIN <CODE4管脚> [get_ports {switch_input[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch_input[*]}]


## ============================================================
## 7-Segment Outputs
## seg_output[7:0] = {A, B, C, D, E, F, G, DP}
## ============================================================

set_property PACKAGE_PIN G14 [get_ports {seg_output[7]}] ;# A
set_property PACKAGE_PIN H13 [get_ports {seg_output[6]}] ;# B
set_property PACKAGE_PIN F12 [get_ports {seg_output[5]}] ;# C
set_property PACKAGE_PIN G12 [get_ports {seg_output[4]}] ;# D
set_property PACKAGE_PIN F9  [get_ports {seg_output[3]}] ;# E
set_property PACKAGE_PIN D11 [get_ports {seg_output[2]}] ;# F
set_property PACKAGE_PIN C11 [get_ports {seg_output[1]}] ;# G
set_property PACKAGE_PIN D8  [get_ports {seg_output[0]}] ;# DP

set_property IOSTANDARD LVCMOS33 [get_ports {seg_output[*]}]


## ============================================================
## Digit Select: COM1-COM4
## ============================================================

set_property PACKAGE_PIN F10 [get_ports {seg_sel[0]}] ;# COM1
set_property PACKAGE_PIN F11 [get_ports {seg_sel[1]}] ;# COM2
set_property PACKAGE_PIN E11 [get_ports {seg_sel[2]}] ;# COM3
set_property PACKAGE_PIN G11 [get_ports {seg_sel[3]}] ;# COM4

set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[*]}]