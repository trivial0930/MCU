# Run from a route project root, for example:
#   cd routes_ultra/V10_width_reduce/mcu_fft_v10_width_reduce
#   D:/vivado/2025.2/Vivado/bin/vivado.bat -mode batch -source ../../vivado/run_no_ila_board_bitstream.tcl

set ENABLE_ILA 0
set TARGET_PERIOD_NS 20.000
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
}
if {![info exists JOBS]} {
    set JOBS 4
}
if {![info exists OUT_DIR]} {
    set route_leaf [file tail [file normalize [pwd]]]
    set OUT_DIR [file normalize [file join "D:/vivado_work/routes_ultra" $route_leaf]]
}

source [file join [file dirname [info script]] run_board_bitstream.tcl]
