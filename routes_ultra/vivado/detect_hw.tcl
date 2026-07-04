open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set devs [get_hw_devices]
puts "devices=$devs"
foreach d $devs {
    puts "device=[get_property PART $d] name=$d"
}
close_hw_manager
