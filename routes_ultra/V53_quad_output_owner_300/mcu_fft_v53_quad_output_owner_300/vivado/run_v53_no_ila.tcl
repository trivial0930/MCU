# Run from this route root:
#   cd routes_ultra/V53_quad_output_owner_300/mcu_fft_v53_quad_output_owner_300
#   D:/vivado/2025.2/Vivado/bin/vivado.bat -mode batch -source vivado/run_v53_no_ila.tcl

set ENABLE_ILA 0
set TARGET_PERIOD_NS 20.000
set SYNTH_FLATTEN_HIERARCHY none
set SYNTH_MAX_DSP 0

if {[llength $argv] >= 1} {
    set FREQ_MHZ [lindex $argv 0]
}
if {![info exists FREQ_MHZ]} {
    set FREQ_MHZ 300
}
switch -- $FREQ_MHZ {
    300 {
        set PLL_CLKFBOUT_MULT 30
        set PLL_CLKOUT0_DIVIDE 5
    }
    275 {
        set PLL_CLKFBOUT_MULT 22
        set PLL_CLKOUT0_DIVIDE 4
    }
    250 {
        set PLL_CLKFBOUT_MULT 25
        set PLL_CLKOUT0_DIVIDE 5
    }
    200 {
        set PLL_CLKFBOUT_MULT 20
        set PLL_CLKOUT0_DIVIDE 5
    }
    default {
        set msg "unsupported FREQ_MHZ=$FREQ_MHZ; use 300, 275, 250, or 200"
        puts "ERROR: $msg"
        error $msg
    }
}

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
}
if {![info exists JOBS]} {
    set JOBS 4
}
if {![info exists OUT_DIR]} {
    set OUT_DIR [file normalize [file join "D:/vivado_work/routes_ultra" "mcu_fft_v53_quad_output_owner_${FREQ_MHZ}"]]
}

proc write_board_status {path status notes} {
    set fd [open $path w]
    puts $fd "status=$status"
    puts $fd "notes=$notes"
    close $fd
}

proc append_note {var_name text} {
    upvar $var_name notes
    lappend notes $text
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

set board_script [file normalize [file join $root_dir .. .. vivado create_board_project.tcl]]
if {![file exists $board_script]} {
    set msg "cannot find shared create_board_project.tcl at $board_script"
    puts "ERROR: $msg"
    write_board_status $status_file failed $msg
    error $msg
}

if {[catch {source $board_script} err]} {
    write_board_status $status_file failed "create_project_error=$err"
    error $err
}

set_property generic "PLL_CLKFBOUT_MULT=$PLL_CLKFBOUT_MULT PLL_CLKOUT0_DIVIDE=$PLL_CLKOUT0_DIVIDE" [current_fileset]

set impl_notes {}
set impl_run [get_runs impl_1]

if {[catch {set_property strategy Performance_ExplorePostRoutePhysOpt $impl_run} err]} {
    append_note impl_notes "impl_strategy_Performance_ExplorePostRoutePhysOpt_failed=$err"
    if {[catch {set_property strategy Performance_Explore $impl_run} fallback_err]} {
        append_note impl_notes "impl_strategy_fallback_failed=$fallback_err"
    } else {
        append_note impl_notes "impl_strategy=Performance_Explore"
    }
} else {
    append_note impl_notes "impl_strategy=Performance_ExplorePostRoutePhysOpt"
}

foreach setting {
    {STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore}
    {STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high}
    {STEPS.PHYS_OPT_DESIGN.IS_ENABLED true}
    {STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore}
    {STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore}
} {
    set prop [lindex $setting 0]
    set value [lindex $setting 1]
    if {[catch {set_property $prop $value $impl_run} err]} {
        append_note impl_notes "${prop}_failed=$err"
    } else {
        append_note impl_notes "${prop}=$value"
    }
}

set run_error ""
if {[catch {
    launch_runs synth_1 -jobs $JOBS
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
    wait_on_run impl_1
} run_error]} {
    write_board_status $status_file failed "run_error=$run_error strategy_notes=$impl_notes"
    error $run_error
}

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
if {[catch {open_run impl_1} err]} {
    write_board_status $status_file failed "open_impl_error=$err synth_status=$synth_status impl_status=$impl_status strategy_notes=$impl_notes"
    error $err
}

report_timing_summary -file [file join $results_dir board_timing_summary.rpt]
report_utilization -file [file join $results_dir board_utilization.rpt]
report_utilization -hierarchical -file [file join $results_dir board_utilization_hierarchical.rpt]
report_drc -file [file join $results_dir board_drc.rpt]
report_methodology -file [file join $results_dir board_methodology.rpt]

set bit_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.bit]]
set ltx_files [glob -nocomplain [file join $out_dir mcu_fft_board.runs impl_1 *.ltx]]
write_board_status $status_file ok "part=$PART_NAME freq_mhz=$FREQ_MHZ pll_mult=$PLL_CLKFBOUT_MULT pll_divide=$PLL_CLKOUT0_DIVIDE target_period_ns=$TARGET_PERIOD_NS enable_ila=$ENABLE_ILA flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP synth_status=$synth_status impl_status=$impl_status strategy_notes=$impl_notes bit_files=$bit_files ltx_files=$ltx_files"

puts "V53 no-ILA board build complete."
puts "Reports: $results_dir"
puts "Bitstream files: $bit_files"
puts "LTX files: $ltx_files"
