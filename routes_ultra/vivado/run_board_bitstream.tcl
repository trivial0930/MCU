# Run from a route project root, for example:
#   cd routesA/speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul
#   vivado -mode batch -source ../../vivado/run_board_bitstream.tcl
#
# Optional overrides before sourcing:
#   set PART_NAME xc7k160tffg676-2
#   set TARGET_PERIOD_NS 20.000
#   set ENABLE_ILA 1
#   set SYNTH_FLATTEN_HIERARCHY none
#   set SYNTH_MAX_DSP 0
#   set JOBS 4

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
}
if {![info exists TARGET_PERIOD_NS]} {
    set TARGET_PERIOD_NS "20.000"
}
if {![info exists ENABLE_ILA]} {
    set ENABLE_ILA 1
}
if {![info exists SYNTH_FLATTEN_HIERARCHY]} {
    set SYNTH_FLATTEN_HIERARCHY "none"
}
if {![info exists SYNTH_MAX_DSP]} {
    set SYNTH_MAX_DSP 0
}
if {![info exists JOBS]} {
    set JOBS 4
}

proc write_board_status {path status notes} {
    set fd [open $path w]
    puts $fd "status=$status"
    puts $fd "notes=$notes"
    close $fd
}

proc find_board_project_script {start_dir} {
    set dir [file normalize $start_dir]
    for {set depth 0} {$depth < 10} {incr depth} {
        set candidate [file normalize [file join $dir vivado create_board_project.tcl]]
        if {[file exists $candidate]} {
            return $candidate
        }
        set parent [file dirname $dir]
        if {$parent eq $dir} {
            break
        }
        set dir $parent
    }
    return ""
}

set root_dir [file normalize [pwd]]
set results_dir [file join $root_dir results vivado_board]
file mkdir $results_dir
set status_file [file join $results_dir board_bitstream_status.txt]

if {[llength [get_parts -quiet $PART_NAME]] == 0} {
    set msg "part=$PART_NAME is not installed in this Vivado device database"
    puts "ERROR: $msg"
    write_board_status $status_file blocked $msg
    error $msg
}

set board_script [find_board_project_script $root_dir]
if {$board_script eq ""} {
    set msg "cannot find create_board_project.tcl while searching upward from $root_dir"
    puts "ERROR: $msg"
    write_board_status $status_file failed $msg
    error $msg
}

if {[catch {source $board_script} err]} {
    write_board_status $status_file failed "create_project_error=$err"
    error $err
}

set run_error ""
if {[catch {
    launch_runs synth_1 -jobs $JOBS
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
    wait_on_run impl_1
} run_error]} {
    write_board_status $status_file failed "run_error=$run_error"
    error $run_error
}

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
if {[catch {open_run impl_1} err]} {
    write_board_status $status_file failed "open_impl_error=$err synth_status=$synth_status impl_status=$impl_status"
    error $err
}

report_timing_summary -file [file join $results_dir board_timing_summary.rpt]
report_utilization -file [file join $results_dir board_utilization.rpt]
report_utilization -hierarchical -file [file join $results_dir board_utilization_hierarchical.rpt]
report_drc -file [file join $results_dir board_drc.rpt]
report_methodology -file [file join $results_dir board_methodology.rpt]

set bit_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.bit]]
set ltx_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.ltx]]
write_board_status $status_file ok "part=$PART_NAME target_period_ns=$TARGET_PERIOD_NS enable_ila=$ENABLE_ILA flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP synth_status=$synth_status impl_status=$impl_status bit_files=$bit_files ltx_files=$ltx_files"

puts "Board build complete."
puts "Reports: $results_dir"
puts "Bitstream files: $bit_files"
puts "LTX files: $ltx_files"
