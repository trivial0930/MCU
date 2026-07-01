`include "defines.vh"

module ext_test_rom_if(
    input  wire [31:0] mem_addr,
    input  wire mem_read,
    input  wire [15:0] test_vector_in,
    output wire [7:0] test_rom_addr,
    output wire [31:0] read_data,
    output wire is_test_rom,
    output wire first_read_pulse
);
    wire [7:0] test_offset;
    wire is_fft_sample;
    wire signed [31:0] signed_test_word;

    assign is_test_rom = (mem_addr >= `TEST_BASE) && (mem_addr < (`TEST_BASE + 32'd256));
    assign test_offset = mem_addr[7:0];
    assign test_rom_addr = is_test_rom ? test_offset : 8'd0;
    assign is_fft_sample = (test_offset >= 8'd128) && (test_offset < 8'd144);
    assign signed_test_word = {{16{test_vector_in[15]}}, test_vector_in};
    assign read_data = is_fft_sample ? (signed_test_word <<< 7) : signed_test_word;
    assign first_read_pulse = mem_read && is_test_rom && (test_offset == 8'd128);
endmodule
