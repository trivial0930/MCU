# Usage:
#   set BIT_FILE D:/vivado_work/routes_ultra/mcu_fft_v10_width_reduce/mcu_fft_board.runs/impl_1/board_top.bit
#   source routes_ultra/vivado/program_bitstream.tcl

if {![info exists BIT_FILE]} {
    error "BIT_FILE is required"
}
if {![file exists $BIT_FILE]} {
    error "BIT_FILE does not exist: $BIT_FILE"
}

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices] 0]
if {$dev eq ""} {
    error "No hardware device found"
}

current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
set_property PROGRAM.FILE $BIT_FILE $dev
program_hw_devices $dev
puts "program_status=ok device=$dev bit=$BIT_FILE"
close_hw_manager
