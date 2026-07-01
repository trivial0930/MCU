# Run from the route project root:
#   source vivado/run_high_freq_sweep.tcl
#
# Set PART_NAME before sourcing when your Vivado install/project uses a
# different Kintex-7 package.

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k325tffg900-2"
}

set root_dir [file normalize [pwd]]
set out_dir  [file join $root_dir build vivado_sweep]
file mkdir $out_dir

set targets {
    {95  10.526}
    {100 10.000}
    {110 9.091}
    {120 8.333}
    {130 7.692}
}

set strategies {
    Performance_Explore
    Performance_ExplorePostRoutePhysOpt
}

foreach target $targets {
    set mhz [lindex $target 0]
    set period [lindex $target 1]

    foreach strategy $strategies {
        set proj_name "mcu_fft_${mhz}mhz_${strategy}"
        set proj_dir [file join $out_dir $proj_name]
        create_project -force $proj_name $proj_dir -part $PART_NAME

        set src_xdc [file join $root_dir constraints top.xdc]
        set dst_xdc [file join $proj_dir "top_${mhz}mhz.xdc"]
        set fd [open $src_xdc r]
        set xdc_text [read $fd]
        close $fd
        regsub {create_clock -period [0-9.]+ -name clk_50m} \
            $xdc_text "create_clock -period $period -name clk_${mhz}m" xdc_text
        set fd [open $dst_xdc w]
        puts $fd $xdc_text
        close $fd

        add_files [glob -nocomplain [file join $root_dir rtl *.v]]
        add_files [glob -nocomplain [file join $root_dir mem *.mem]]
        add_files [glob -nocomplain [file join $root_dir mem *.coe]]
        add_files -fileset constrs_1 $dst_xdc
        set_property top board_top [current_fileset]
        set_property include_dirs [file join $root_dir rtl] [current_fileset]
        set_property verilog_define {SYNTHESIS} [current_fileset]

        update_compile_order -fileset sources_1
        set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
        set_property strategy $strategy [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

        launch_runs impl_1 -to_step route_design -jobs 4
        wait_on_run impl_1
        open_run impl_1

        set report_prefix [file join $proj_dir "${proj_name}"]
        report_timing_summary -file "${report_prefix}_timing_summary.rpt"
        report_utilization -file "${report_prefix}_utilization.rpt"
        write_checkpoint -force "${report_prefix}_routed.dcp"
        close_project
    }
}
