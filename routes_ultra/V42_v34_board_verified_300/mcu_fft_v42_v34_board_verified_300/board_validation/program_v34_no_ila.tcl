set BIT_FILE D:/vivado_work/routes_ultra/mcu_fft_v34_dual_mcu_schedule_300/mcu_fft_board.runs/impl_1/board_top.bit
source [file normalize "../../vivado/program_bitstream.tcl"]

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
puts "device=$dev"
puts "ilas_after_no_ila_program=[llength [get_hw_ilas]]"
close_hw_manager
