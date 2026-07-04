## K7EDAEVAL board constraints for board_top.v
## Pin source: K7EDAEVAL pin definition spreadsheet.

set_property PACKAGE_PIN G22 [get_ports CLK_50M]
set_property IOSTANDARD LVCMOS33 [get_ports CLK_50M]
create_clock -period 20.000 -name clk_50m [get_ports CLK_50M]

## KEY1 is used as active-low reset in board_top.v.
set_property PACKAGE_PIN AF5 [get_ports KEY1]
set_property IOSTANDARD LVCMOS18 [get_ports KEY1]

set_property PACKAGE_PIN G9 [get_ports LED1]
set_property IOSTANDARD LVCMOS33 [get_ports LED1]
set_property PACKAGE_PIN F8 [get_ports LED2]
set_property IOSTANDARD LVCMOS33 [get_ports LED2]
set_property PACKAGE_PIN G10 [get_ports LED3]
set_property IOSTANDARD LVCMOS33 [get_ports LED3]
set_property PACKAGE_PIN E10 [get_ports LED4]
set_property IOSTANDARD LVCMOS33 [get_ports LED4]
set_property PACKAGE_PIN D9 [get_ports LED5]
set_property IOSTANDARD LVCMOS33 [get_ports LED5]
set_property PACKAGE_PIN B9 [get_ports LED6]
set_property IOSTANDARD LVCMOS33 [get_ports LED6]
set_property PACKAGE_PIN C9 [get_ports LED7]
set_property IOSTANDARD LVCMOS33 [get_ports LED7]
set_property PACKAGE_PIN A8 [get_ports LED8]
set_property IOSTANDARD LVCMOS33 [get_ports LED8]

## Conservative defaults for button/LED IO.
set_property PULLUP true [get_ports KEY1]
