`include "defines.vh"

module verify_ram_if(
    input  wire is_verify_ram,
    input  wire [4:0] verify_offset,
    input  wire mem_write,
    input  wire signed [24:0] write_data,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire last_write_pulse
);
    assign verify_addr = is_verify_ram ? verify_offset : 5'd0;
    assign verify_vector_out = write_data[15:0];
    assign verify_we = mem_write && is_verify_ram;
    assign last_write_pulse = verify_we && (verify_offset == 5'd15);
endmodule
