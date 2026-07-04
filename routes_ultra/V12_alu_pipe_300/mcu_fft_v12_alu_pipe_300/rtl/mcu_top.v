module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [7:0] test_rom_addr,
    input  wire [15:0] test_vector_in,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [19:0] cnt_test,
    output wire done
);
    wire [15:0] instr_addr;
    wire [31:0] instr;
    wire [15:0] dmem_addr;
    wire [15:0] dmem_wdata;
    wire dmem_we;
    wire [15:0] dmem_rdata;
    wire first_test_rom_read;
    wire last_verify_ram_write;

    instr_rom u_instr_rom(
        .addr(instr_addr),
        .instr(instr)
    );

    data_ram u_data_ram(
        .clk(clk),
        .we(dmem_we),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata)
    );

    mcu_core u_mcu_core(
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr),
        .instr(instr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata),
        .test_rom_addr(test_rom_addr),
        .test_vector_in(test_vector_in),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .first_test_rom_read(first_test_rom_read),
        .last_verify_ram_write(last_verify_ram_write),
        .done(done)
    );

    cnt_test_unit u_cnt_test(
        .clk(clk),
        .rst(rst),
        .start_pulse(first_test_rom_read),
        .stop_pulse(last_verify_ram_write),
        .cnt_test(cnt_test)
    );
endmodule
