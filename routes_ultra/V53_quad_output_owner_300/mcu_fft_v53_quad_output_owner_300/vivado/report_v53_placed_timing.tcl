if {![info exists DCP_PATH]} {
    set DCP_PATH "D:/vivado_work/routes_ultra/mcu_fft_v53_quad_output_owner_300/mcu_fft_board.runs/impl_1/board_top_placed.dcp"
}

set root_dir [file normalize [pwd]]
set out_dir [file join $root_dir results vivado_board placed_debug]
file mkdir $out_dir

open_checkpoint $DCP_PATH
report_timing_summary -file [file join $out_dir placed_timing_summary.rpt]
report_timing -max_paths 20 -sort_by slack -path_type full -file [file join $out_dir placed_worst_paths.rpt]
report_high_fanout_nets -timing -load_types -max_nets 50 -file [file join $out_dir placed_high_fanout_nets.rpt]
report_utilization -file [file join $out_dir placed_utilization.rpt]

puts "Placed timing debug reports written to $out_dir"
