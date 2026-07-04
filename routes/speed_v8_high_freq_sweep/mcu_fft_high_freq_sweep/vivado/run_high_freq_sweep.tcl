# Run from the route project root:
#   cd routes/speed_v8_high_freq_sweep/mcu_fft_high_freq_sweep
#   vivado -mode batch -source vivado/run_high_freq_sweep.tcl
#
# Optional overrides before sourcing:
#   set PART_NAME xc7k160tffg676-2
#   set SYNTH_FLATTEN_HIERARCHY none
#   set SYNTH_MAX_DSP 0
#   set JOBS 4
#   set OUT_DIR D:/vivado_work/mcu_high_freq_sweep

if {![info exists PART_NAME]} {
    set PART_NAME "xc7k160tffg676-2"
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

proc replace_clock_constraint {src_xdc dst_xdc period mhz} {
    set fd [open $src_xdc r]
    set xdc_text [read $fd]
    close $fd

    set replaced [regsub {create_clock -period [0-9.]+ -name clk_50m} \
        $xdc_text "create_clock -period $period -name clk_${mhz}m" xdc_text]
    if {!$replaced} {
        error "Cannot find the clk_50m create_clock line in $src_xdc"
    }

    set fd [open $dst_xdc w]
    puts $fd $xdc_text
    close $fd
}

proc add_route_sources {root_dir xdc_file} {
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

    add_files -fileset constrs_1 $xdc_file
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

proc set_synth_init_files {proj_dir root_dir} {
    set pre_tcl [file join $proj_dir synth_pre_files.tcl]
    set init_files [concat \
        [glob -nocomplain [file join $root_dir mem *.mem]] \
        [glob -nocomplain [file join $root_dir mem *.coe]]]
    set fd [open $pre_tcl w]
    puts $fd "file mkdir mem"
    puts $fd "foreach f {$init_files} {"
    puts $fd "    file copy -force \$f mem"
    puts $fd "}"
    close $fd
    set_property STEPS.SYNTH_DESIGN.TCL.PRE $pre_tcl [get_runs synth_1]
}

set root_dir [file normalize [pwd]]
if {![info exists OUT_DIR]} {
    set OUT_DIR [file join $root_dir build vivado_sweep]
}
set out_dir [file normalize $OUT_DIR]
file mkdir $out_dir

set src_xdc [file join $root_dir constraints top.xdc]
if {![file exists $src_xdc]} {
    error "Missing constraint file: $src_xdc"
}

set targets {
    {95  10.526}
    {100 10.000}
    {110 9.091}
    {120 8.333}
    {130 7.692}
}

set strategies {
    Performance_Explore
}

foreach target $targets {
    set mhz [lindex $target 0]
    set period [lindex $target 1]

    foreach strategy $strategies {
        set proj_name "mcu_fft_${mhz}mhz_${strategy}"
        set proj_dir [file join $out_dir $proj_name]
        set status_file [file join $proj_dir "run_status.txt"]
        file mkdir $proj_dir

        puts "=== Running $proj_name on $PART_NAME, target ${mhz} MHz ($period ns), strategy $strategy ==="
        create_project -force $proj_name $proj_dir -part $PART_NAME

        set dst_xdc [file join $proj_dir "top_${mhz}mhz.xdc"]
        replace_clock_constraint $src_xdc $dst_xdc $period $mhz
        add_route_sources $root_dir $dst_xdc

        set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
        set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY $SYNTH_FLATTEN_HIERARCHY [get_runs synth_1]
        set_property STEPS.SYNTH_DESIGN.ARGS.MAX_DSP $SYNTH_MAX_DSP [get_runs synth_1]
        set_property strategy $strategy [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
        set_synth_init_files $proj_dir $root_dir

        set run_error ""
        if {[catch {
            launch_runs impl_1 -to_step route_design -jobs $JOBS
            wait_on_run impl_1
        } run_error]} {
            puts "WARNING: implementation run failed for $proj_name: $run_error"
            write_status $status_file failed "target_mhz=$mhz strategy=$strategy part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP error=$run_error"
            close_project
            continue
        }
        set run_status [get_property STATUS [get_runs impl_1]]
        write_status $status_file $run_status "target_mhz=$mhz strategy=$strategy part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP"

        if {[catch {open_run impl_1} err]} {
            puts "WARNING: cannot open implemented run for $proj_name: $err"
            close_project
            continue
        }

        set report_prefix [file join $proj_dir "${proj_name}"]
        report_timing_summary -file "${report_prefix}_timing_summary.rpt"
        report_utilization -file "${report_prefix}_utilization.rpt"
        report_utilization -hierarchical -file "${report_prefix}_utilization_hierarchical.rpt"
        report_design_analysis -timing -file "${report_prefix}_design_analysis_timing.rpt"
        write_checkpoint -force "${report_prefix}_routed.dcp"
        close_project
    }
}
