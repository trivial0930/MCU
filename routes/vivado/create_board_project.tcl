# Run from a route project root, for example:
#   cd routes/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
#   set PART_NAME xc7k160tffg676-2
#   set TARGET_PERIOD_NS 20.000
#   set ENABLE_ILA 1
#   set SYNTH_FLATTEN_HIERARCHY none
#   set SYNTH_MAX_DSP 0
#   source ../../vivado/create_board_project.tcl

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
}

if {![info exists TARGET_PERIOD_NS]} {
    set TARGET_PERIOD_NS "20.000"
}

if {![info exists SYNTH_FLATTEN_HIERARCHY]} {
    set SYNTH_FLATTEN_HIERARCHY "none"
}

if {![info exists SYNTH_MAX_DSP]} {
    set SYNTH_MAX_DSP 0
}

if {![info exists ENABLE_ILA]} {
    set ENABLE_ILA 0
}

set root_dir [file normalize [pwd]]
if {![info exists OUT_DIR]} {
    set OUT_DIR [file join $root_dir build vivado_board]
}
set out_dir [file normalize $OUT_DIR]
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
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY $SYNTH_FLATTEN_HIERARCHY [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.MAX_DSP $SYNTH_MAX_DSP [get_runs synth_1]
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

set synth_pre_tcl [file join $out_dir synth_pre_cd.tcl]
set init_files [concat \
    [glob -nocomplain [file join $root_dir mem *.mem]] \
    [glob -nocomplain [file join $root_dir mem *.coe]]]
set fd [open $synth_pre_tcl w]
puts $fd "file mkdir mem"
puts $fd "foreach f {$init_files} {"
puts $fd "    file copy -force \$f mem"
puts $fd "}"
close $fd
set_property STEPS.SYNTH_DESIGN.TCL.PRE $synth_pre_tcl [get_runs synth_1]

update_compile_order -fileset sources_1

puts "Created board project at $out_dir"
puts "Target period: $TARGET_PERIOD_NS ns"
puts "ENABLE_ILA: $ENABLE_ILA"
puts "SYNTH_FLATTEN_HIERARCHY: $SYNTH_FLATTEN_HIERARCHY"
puts "SYNTH_MAX_DSP: $SYNTH_MAX_DSP"
