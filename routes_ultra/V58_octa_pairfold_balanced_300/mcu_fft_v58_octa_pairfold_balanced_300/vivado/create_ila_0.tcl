create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {6} \
    CONFIG.C_PROBE0_WIDTH {16} \
    CONFIG.C_PROBE1_WIDTH {128} \
    CONFIG.C_PROBE2_WIDTH {8} \
    CONFIG.C_PROBE3_WIDTH {40} \
    CONFIG.C_PROBE4_WIDTH {20} \
    CONFIG.C_PROBE5_WIDTH {1} \
] [get_ips ila_0]
generate_target all [get_ips ila_0]
