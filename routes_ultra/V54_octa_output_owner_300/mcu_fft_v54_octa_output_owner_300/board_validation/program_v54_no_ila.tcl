set route_root [file normalize [pwd]]
set base_dir [file join $route_root board_validation]
set status_file [file join $base_dir "no_ila_program_status.txt"]
set BIT_FILE [file normalize "D:/vivado_work/routes_ultra/mcu_fft_v54_octa_output_owner_300/mcu_fft_board.runs/impl_1/board_top.bit"]

file mkdir $base_dir
set fd [open $status_file w]
proc log_line {fd msg} {
    puts $msg
    puts $fd $msg
    flush $fd
}

if {![file exists $BIT_FILE]} {
    log_line $fd "ERROR=bit file does not exist: $BIT_FILE"
    close $fd
    exit 1
}

if {[catch {
    source [file normalize "../../vivado/program_bitstream.tcl"]

    open_hw_manager
    connect_hw_server -allow_non_jtag
    open_hw_target
    set dev [lindex [get_hw_devices] 0]
    current_hw_device $dev
    refresh_hw_device -update_hw_probes false $dev
    log_line $fd "program_status=ok"
    log_line $fd "device=$dev"
    log_line $fd "bit_file=$BIT_FILE"
    log_line $fd "ilas_after_no_ila_program=[llength [get_hw_ilas]]"
    close_hw_manager
} err]} {
    log_line $fd "ERROR=$err"
    close $fd
    exit 1
}

close $fd
exit 0
