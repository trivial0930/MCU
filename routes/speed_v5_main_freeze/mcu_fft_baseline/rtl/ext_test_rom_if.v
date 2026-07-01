`include "defines.vh"

module ext_test_rom_if(
    input  wire [31:0] mem_addr,
    input  wire mem_read,
    input  wire [15:0] test_vector_in,
    output wire [4:0] test_rom_addr,
    output wire [31:0] read_data,
    output wire is_test_rom,
    output wire first_read_pulse
);
    assign is_test_rom = (mem_addr >= `TEST_BASE) && (mem_addr < (`TEST_BASE + 32'd16));
    assign test_rom_addr = is_test_rom ? mem_addr[4:0] : 5'd0;
    assign read_data = {{16{test_vector_in[15]}}, test_vector_in};
    assign first_read_pulse = mem_read && is_test_rom && (mem_addr == `TEST_BASE);
endmodule
