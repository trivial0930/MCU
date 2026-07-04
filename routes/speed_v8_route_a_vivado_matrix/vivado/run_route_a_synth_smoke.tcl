# Run from this folder through an ASCII/short path when possible:
#   cd routes/speed_v8_route_a_vivado_matrix
#   vivado -mode batch -source vivado/run_route_a_synth_smoke.tcl
#
# This script is a Vivado compile smoke test. It intentionally skips board XDC
# constraints so it can run on an installed substitute part when the exact
# K7EDAEVAL part package is unavailable. Do not use these reports as final
# board timing results.
#
# Optional overrides:
#   set PART_NAME xc7k160tffg676-2
#   set SYNTH_FLATTEN_HIERARCHY none
#   set SYNTH_MAX_DSP 0
#   set CANDIDATES {{speed_v7_q7_narrow_mul ../speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul}}

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
}
if {![info exists SYNTH_FLATTEN_HIERARCHY]} {
    set SYNTH_FLATTEN_HIERARCHY "none"
}
if {![info exists SYNTH_MAX_DSP]} {
    set SYNTH_MAX_DSP 0
}

if {![info exists CANDIDATES]} {
    set CANDIDATES {
        {speed_v6_official_sample ../speed_v6_official_sample/mcu_fft_official_sample}
        {speed_v7_q7_narrow_mul ../speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul}
        {speed_v7b_c91_shift_add ../speed_v7b_c91_shift_add/mcu_fft_c91_shift_add}
        {speed_v7c_c91_shift_sub ../speed_v7c_c91_shift_sub/mcu_fft_c91_shift_sub}
    }
}

proc add_route_sources {root_dir} {
    set rtl_files [glob -nocomplain [file join $root_dir rtl *.v]]
    if {[llength $rtl_files] == 0} {
        error "No RTL files found under [file join $root_dir rtl]"
    }
    add_files $rtl_files

    set mem_files [concat \
        [glob -nocomplain [file join $root_dir mem *.mem]] \
        [glob -nocomplain [file join $root_dir mem *.coe]]]
    if {[llength $mem_files] > 0} {
        add_files $mem_files
    }

    set_property top board_top [current_fileset]
    set_property include_dirs [file join $root_dir rtl] [current_fileset]
    set_property verilog_define {SYNTHESIS} [current_fileset]
    update_compile_order -fileset sources_1
}

proc write_status {path status notes} {
    set fd [open $path w]
    puts $fd "status=$status"
    puts $fd "notes=$notes"
    close $fd
}

set matrix_dir [file normalize [pwd]]
if {![info exists OUT_DIR]} {
    set OUT_DIR [file join $matrix_dir build vivado_synth_smoke]
}
set out_dir [file normalize $OUT_DIR]
file mkdir $out_dir

foreach candidate $CANDIDATES {
    set route_name [lindex $candidate 0]
    set rel_root [lindex $candidate 1]
    set root_dir [file normalize [file join $matrix_dir $rel_root]]
    set proj_name "${route_name}_synth_${PART_NAME}"
    set proj_dir [file join $out_dir $proj_name]
    set status_file [file join $proj_dir run_status.txt]

    puts "=== Synth smoke $route_name on $PART_NAME ==="
    create_project -force $proj_name $proj_dir -part $PART_NAME
    add_route_sources $root_dir

    cd $root_dir
    if {[catch {synth_design -top board_top -part $PART_NAME -flatten_hierarchy $SYNTH_FLATTEN_HIERARCHY -max_dsp $SYNTH_MAX_DSP} err]} {
        puts "ERROR: synth smoke failed for $route_name: $err"
        write_status $status_file failed "route=$route_name part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP error=$err"
        cd $matrix_dir
        close_project
        continue
    }
    cd $matrix_dir

    report_utilization -file [file join $proj_dir "${proj_name}_utilization.rpt"]
    report_utilization -hierarchical -file [file join $proj_dir "${proj_name}_utilization_hierarchical.rpt"]
    report_timing_summary -file [file join $proj_dir "${proj_name}_timing_summary.rpt"]
    write_checkpoint -force [file join $proj_dir "${proj_name}_synth.dcp"]
    write_status $status_file ok "route=$route_name part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP xdc=skipped"
    close_project
}
