set src_dir [file normalize [file join [pwd] rtl]]
set tb_dir  [file normalize [file join [pwd] tb]]
set mem_dir [file normalize [file join [pwd] mem]]
set xdc_dir [file normalize [file join [pwd] constraints]]

add_files [glob -nocomplain [file join $src_dir *.v]]
add_files -fileset constrs_1 [file join $xdc_dir top.xdc]
add_files -fileset sim_1 [glob -nocomplain [file join $tb_dir *.v]]
add_files [glob -nocomplain [file join $mem_dir *.mem]]
add_files [glob -nocomplain [file join $mem_dir *.coe]]

if {![info exists ENABLE_ILA]} {
    set ENABLE_ILA 0
}
if {![info exists EXTRA_VERILOG_DEFINES]} {
    set EXTRA_VERILOG_DEFINES {}
}

if {$ENABLE_ILA} {
    if {[llength [get_ips -quiet ila_0]] == 0} {
        source [file join [pwd] vivado create_ila_0.tcl]
    }
    set_property verilog_define [concat {SYNTHESIS ENABLE_ILA} $EXTRA_VERILOG_DEFINES] [current_fileset]
} else {
    set_property verilog_define [concat {SYNTHESIS} $EXTRA_VERILOG_DEFINES] [current_fileset]
}

set_property top board_top [current_fileset]
set_property include_dirs $src_dir [current_fileset]

puts "Added V53 quad MCU FFT sources, constraints, memory init files, and optional ila_0 IP."
