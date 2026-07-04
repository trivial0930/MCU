`include "defines.vh"

module ext_test_rom_if(
    input  wire is_test_rom,
    input  wire [7:0] test_offset,
    input  wire mem_read,
    input  wire [15:0] test_vector_in,
    output wire [7:0] test_rom_addr,
    output wire signed [31:0] read_data,
    output wire first_read_pulse
);
    wire is_fft_sample;
    wire signed [31:0] signed_test_word;

    assign test_rom_addr = is_test_rom ? test_offset : 8'd0;
    assign is_fft_sample = (test_offset >= 8'd128) && (test_offset < 8'd144);
    assign signed_test_word = {{16{test_vector_in[15]}}, test_vector_in};
    assign read_data = is_fft_sample ? (signed_test_word <<< 7) : signed_test_word;
    assign first_read_pulse = mem_read && is_test_rom && (test_offset == 8'd128);
endmodule
