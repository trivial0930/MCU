`include "defines.vh"

module verify_ram_if(
    input  wire [31:0] mem_addr,
    input  wire mem_write,
    input  wire [31:0] write_data,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire last_write_pulse
);
    wire is_verify_ram;

    assign is_verify_ram = (mem_addr >= `VERIFY_BASE) && (mem_addr < (`VERIFY_BASE + 32'd16));
    assign verify_addr = is_verify_ram ? mem_addr[4:0] : 5'd0;
    assign verify_vector_out = write_data[15:0];
    assign verify_we = mem_write && is_verify_ram;
    assign last_write_pulse = verify_we && (mem_addr == (`VERIFY_BASE + 32'd15));
endmodule
