# Run from repository root or this route folder:
#   vivado -mode batch -source routes/speed_v9_cycle_reduce/run_vivado_130.tcl

set script_dir [file dirname [file normalize [info script]]]
set matrix_dir [file normalize [file join $script_dir .. speed_v8_route_a_vivado_matrix]]

cd $matrix_dir

set PART_NAME "xc7k160tffg676-2"
set SYNTH_FLATTEN_HIERARCHY "none"
set SYNTH_MAX_DSP 0
if {![info exists JOBS]} {
    set JOBS 4
}
if {![info exists OUT_DIR]} {
    set OUT_DIR [file normalize [file join $script_dir build vivado_130]]
}
set CANDIDATES {
    {speed_v9_cycle_reduce ../speed_v9_cycle_reduce/mcu_fft_cycle_reduce}
}
set TARGETS {
    {130 7.692}
}
set STRATEGIES {
    Performance_Explore
}

source [file join $matrix_dir vivado run_route_a_matrix.tcl]
