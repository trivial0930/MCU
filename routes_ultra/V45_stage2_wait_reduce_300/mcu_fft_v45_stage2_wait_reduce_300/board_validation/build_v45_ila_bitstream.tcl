set ENABLE_ILA 1
set TARGET_PERIOD_NS 20.000
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0
set PART_NAME xc7k160tffg676-2
set JOBS 4

set OUT_DIR [file normalize "D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_ila"]
set root_dir [file normalize [pwd]]
set reports_dir [file join $root_dir board_validation vivado_ila]
set status_file [file join $reports_dir v45_ila_bitstream_status.txt]
file mkdir $reports_dir

proc write_status {path status notes} {
    set fd [open $path w]
    puts $fd "status=$status"
    puts $fd "notes=$notes"
    close $fd
}

if {[catch {
    source [file normalize "../../vivado/create_board_project.tcl"]

    launch_runs synth_1 -jobs $JOBS
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
    wait_on_run impl_1

    set synth_status [get_property STATUS [get_runs synth_1]]
    set impl_status [get_property STATUS [get_runs impl_1]]
    open_run impl_1

    report_timing_summary -file [file join $reports_dir v45_ila_timing_summary.rpt]
    report_utilization -file [file join $reports_dir v45_ila_utilization.rpt]
    report_utilization -hierarchical -file [file join $reports_dir v45_ila_utilization_hierarchical.rpt]
    report_drc -file [file join $reports_dir v45_ila_drc.rpt]
    report_methodology -file [file join $reports_dir v45_ila_methodology.rpt]

    set bit_files [glob -nocomplain [file join $OUT_DIR mcu_fft_board.runs impl_1 *.bit]]
    set ltx_files [glob -nocomplain [file join $OUT_DIR mcu_fft_board.runs impl_1 *.ltx]]
    if {[llength $bit_files] == 0} {
        error "ILA bitstream was not generated"
    }
    if {[llength $ltx_files] == 0} {
        error "ILA probes file was not generated"
    }
    write_status $status_file ok "part=$PART_NAME target_period_ns=$TARGET_PERIOD_NS enable_ila=$ENABLE_ILA synth_status=$synth_status impl_status=$impl_status bit_files=$bit_files ltx_files=$ltx_files"
    puts "V45 ILA build complete."
    puts "Reports: $reports_dir"
    puts "Bitstream files: $bit_files"
    puts "LTX files: $ltx_files"
} err]} {
    write_status $status_file failed $err
    error $err
}
