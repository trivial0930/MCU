# Run from a route project root, for example:
#   cd routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
#   set PART_NAME xc7k325tffg900-2
#   set TARGET_PERIOD_NS 20.000
#   set ENABLE_ILA 1
#   source ../../vivado/create_board_project.tcl

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k325tffg900-2"
}

if {![info exists TARGET_PERIOD_NS]} {
    set TARGET_PERIOD_NS "20.000"
}

if {![info exists ENABLE_ILA]} {
    set ENABLE_ILA 0
}

set root_dir [file normalize [pwd]]
set out_dir [file join $root_dir build vivado_board]
set proj_name "mcu_fft_board"
file mkdir $out_dir

create_project -force $proj_name $out_dir -part $PART_NAME

set src_xdc [file join $root_dir constraints top.xdc]
set dst_xdc [file join $out_dir "top_board.xdc"]
set fd [open $src_xdc r]
set xdc_text [read $fd]
close $fd
regsub {create_clock -period [0-9.]+ -name clk_50m} \
    $xdc_text "create_clock -period $TARGET_PERIOD_NS -name clk_target" xdc_text
set fd [open $dst_xdc w]
puts $fd $xdc_text
close $fd

add_files [glob -nocomplain [file join $root_dir rtl *.v]]
add_files [glob -nocomplain [file join $root_dir mem *.mem]]
add_files [glob -nocomplain [file join $root_dir mem *.coe]]
add_files -fileset constrs_1 $dst_xdc

if {$ENABLE_ILA} {
    if {[file exists [file join $root_dir vivado create_ila_0.tcl]]} {
        source [file join $root_dir vivado create_ila_0.tcl]
    }
    set_property verilog_define {SYNTHESIS ENABLE_ILA} [current_fileset]
} else {
    set_property verilog_define {SYNTHESIS} [current_fileset]
}

set_property top board_top [current_fileset]
set_property include_dirs [file join $root_dir rtl] [current_fileset]
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
update_compile_order -fileset sources_1

puts "Created board project at $out_dir"
puts "Target period: $TARGET_PERIOD_NS ns"
puts "ENABLE_ILA: $ENABLE_ILA"
