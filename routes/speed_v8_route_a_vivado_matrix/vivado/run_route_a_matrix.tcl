# Run from this folder:
#   cd routes/speed_v8_route_a_vivado_matrix
#   vivado -mode batch -source vivado/run_route_a_matrix.tcl
#
# Optional overrides before sourcing:
#   set PART_NAME xc7k160tffg676-2
#   set SYNTH_FLATTEN_HIERARCHY none
#   set SYNTH_MAX_DSP 0
#   set JOBS 4
#   set OUT_DIR D:/vivado_work/mcu_route_a_matrix

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

set matrix_dir [file normalize [pwd]]
if {![info exists OUT_DIR]} {
    set OUT_DIR [file join $matrix_dir build vivado_matrix]
}
set out_dir [file normalize $OUT_DIR]
file mkdir $out_dir

if {![info exists CANDIDATES]} {
    set CANDIDATES {
        {speed_v6_official_sample ../speed_v6_official_sample/mcu_fft_official_sample}
        {speed_v7_q7_narrow_mul ../speed_v7_q7_narrow_mul/mcu_fft_q7_narrow_mul}
        {speed_v7b_c91_shift_add ../speed_v7b_c91_shift_add/mcu_fft_c91_shift_add}
        {speed_v7c_c91_shift_sub ../speed_v7c_c91_shift_sub/mcu_fft_c91_shift_sub}
    }
}

if {![info exists TARGETS]} {
    set TARGETS {
        {95  10.526}
        {100 10.000}
        {110 9.091}
        {120 8.333}
        {130 7.692}
    }
}

if {![info exists STRATEGIES]} {
    set STRATEGIES {
        Performance_Explore
    }
}

foreach candidate $CANDIDATES {
    set route_name [lindex $candidate 0]
    set rel_root [lindex $candidate 1]
    set root_dir [file normalize [file join $matrix_dir $rel_root]]
    set src_xdc [file join $root_dir constraints top.xdc]

    if {![file exists $src_xdc]} {
        puts "WARNING: skip $route_name because constraint file is missing: $src_xdc"
        continue
    }

    foreach target $TARGETS {
        set mhz [lindex $target 0]
        set period [lindex $target 1]

        foreach strategy $STRATEGIES {
            set proj_name "${route_name}_${mhz}mhz_${strategy}"
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
                write_status $status_file failed "route=$route_name target_mhz=$mhz strategy=$strategy part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP error=$run_error"
                close_project
                continue
            }
            set run_status [get_property STATUS [get_runs impl_1]]
            write_status $status_file $run_status "route=$route_name target_mhz=$mhz strategy=$strategy part=$PART_NAME flatten_hierarchy=$SYNTH_FLATTEN_HIERARCHY max_dsp=$SYNTH_MAX_DSP"

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
}
