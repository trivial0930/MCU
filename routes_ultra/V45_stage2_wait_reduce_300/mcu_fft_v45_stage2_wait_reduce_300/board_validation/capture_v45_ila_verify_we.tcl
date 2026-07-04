set route_root [file normalize [pwd]]
set base_dir [file join $route_root board_validation]
set status_file [file join $base_dir "capture_v45_ila_status.txt"]
set bit_file [file normalize "D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_ila/mcu_fft_board.runs/impl_1/board_top.bit"]
set ltx_file [file normalize "D:/vivado_work/routes_ultra/mcu_fft_v45_stage2_wait_reduce_300_ila/mcu_fft_board.runs/impl_1/debug_nets.ltx"]
set csv_file [file join $base_dir "v45_ila_verify_we_capture.csv"]

file mkdir $base_dir
set fd [open $status_file w]
proc log_line {fd msg} {
    puts $msg
    puts $fd $msg
    flush $fd
}

if {![file exists $bit_file]} {
    log_line $fd "ERROR=bit file does not exist: $bit_file"
    close $fd
    exit 1
}
if {![file exists $ltx_file]} {
    log_line $fd "ERROR=ltx file does not exist: $ltx_file"
    close $fd
    exit 1
}

if {[catch {
    open_hw_manager
    connect_hw_server -allow_non_jtag
    current_hw_target [lindex [get_hw_targets] 0]
    open_hw_target
    current_hw_device [lindex [get_hw_devices] 0]
    set dev [current_hw_device]

    set_property PROGRAM.FILE $bit_file $dev
    set_property PROBES.FILE $ltx_file $dev
    set_property FULL_PROBES.FILE $ltx_file $dev
    program_hw_devices $dev
    refresh_hw_device $dev

    set ila [lindex [get_hw_ilas] 0]
    if {$ila eq ""} {
        error "no ILA found after programming"
    }
    current_hw_ila $ila
    reset_hw_ila $ila
    set_property CONTROL.DATA_DEPTH 1024 $ila
    set_property CONTROL.TRIGGER_POSITION 16 $ila
    set_property CONTROL.TRIGGER_CONDITION AND $ila

    set verify_we_probe [lindex [get_hw_probes u_ila_probe/verify_we -of_objects $ila] 0]
    if {$verify_we_probe eq ""} {
        error "cannot find verify_we probe"
    }
    set_property TRIGGER_COMPARE_VALUE {eq1'b1} $verify_we_probe

    log_line $fd "program_status=ok"
    log_line $fd "device=$dev"
    log_line $fd "ila=$ila"
    log_line $fd "armed_for=verify_we_eq_1"
    log_line $fd "action=press_and_release_KEY1_reset"
    run_hw_ila $ila
    wait_on_hw_ila -timeout 90 $ila
    set data [upload_hw_ila_data $ila]
    write_hw_ila_data -force -csv_file $csv_file $data
    log_line $fd "capture_status=ok"
    log_line $fd "csv=board_validation/v45_ila_verify_we_capture.csv"
} err]} {
    log_line $fd "ERROR=$err"
    close $fd
    exit 1
}

close $fd
exit 0
