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
    wire [15:0] instr_addr_core0;
    wire [31:0] instr_core0;
    wire [15:0] dmem_addr_core0;
    wire [15:0] dmem_wdata_core0;
    wire dmem_we_core0;
    wire [15:0] dmem_rdata_core0;
    wire [7:0] test_rom_addr_core0;
    wire [4:0] verify_addr_core0;
    wire [15:0] verify_vector_out_core0;
    wire verify_we_core0;
    wire first_test_rom_read_core0;
    wire last_verify_ram_write_core0;
    wire done_core0;

    wire [15:0] instr_addr_core1;
    wire [31:0] instr_core1;
    wire [15:0] dmem_addr_core1;
    wire [15:0] dmem_wdata_core1;
    wire dmem_we_core1;
    wire [15:0] dmem_rdata_core1;
    wire [7:0] test_rom_addr_core1;
    wire [4:0] verify_addr_core1;
    wire [15:0] verify_vector_out_core1;
    wire verify_we_core1;
    wire first_test_rom_read_core1;
    wire last_verify_ram_write_core1;
    wire done_core1;

    instr_rom u_instr_rom_core0(
        .addr(instr_addr_core0),
        .instr(instr_core0)
    );

    instr_rom #(
        .INIT_FILE("mem/instr_core1.mem")
    ) u_instr_rom_core1(
        .addr(instr_addr_core1),
        .instr(instr_core1)
    );

    shared_data_ram u_shared_data_ram(
        .clk(clk),
        .we0(dmem_we_core0),
        .addr0(dmem_addr_core0),
        .wdata0(dmem_wdata_core0),
        .rdata0(dmem_rdata_core0),
        .we1(dmem_we_core1),
        .addr1(dmem_addr_core1),
        .wdata1(dmem_wdata_core1),
        .rdata1(dmem_rdata_core1)
    );

    mcu_core u_mcu_core0(
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr_core0),
        .instr(instr_core0),
        .dmem_addr(dmem_addr_core0),
        .dmem_wdata(dmem_wdata_core0),
        .dmem_we(dmem_we_core0),
        .dmem_rdata(dmem_rdata_core0),
        .test_rom_addr(test_rom_addr_core0),
        .test_vector_in(test_vector_in),
        .verify_addr(verify_addr_core0),
        .verify_vector_out(verify_vector_out_core0),
        .verify_we(verify_we_core0),
        .first_test_rom_read(first_test_rom_read_core0),
        .last_verify_ram_write(last_verify_ram_write_core0),
        .done(done_core0)
    );

    mcu_core u_mcu_core1(
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr_core1),
        .instr(instr_core1),
        .dmem_addr(dmem_addr_core1),
        .dmem_wdata(dmem_wdata_core1),
        .dmem_we(dmem_we_core1),
        .dmem_rdata(dmem_rdata_core1),
        .test_rom_addr(test_rom_addr_core1),
        .test_vector_in(test_vector_in),
        .verify_addr(verify_addr_core1),
        .verify_vector_out(verify_vector_out_core1),
        .verify_we(verify_we_core1),
        .first_test_rom_read(first_test_rom_read_core1),
        .last_verify_ram_write(last_verify_ram_write_core1),
        .done(done_core1)
    );

    cnt_test_unit u_cnt_test(
        .clk(clk),
        .rst(rst),
        .start_pulse(first_test_rom_read_core0 | first_test_rom_read_core1),
        .stop_pulse(last_verify_ram_write_core0 | last_verify_ram_write_core1),
        .cnt_test(cnt_test)
    );

    assign test_rom_addr = test_rom_addr_core0;
    assign verify_we = verify_we_core1 ? 1'b1 : verify_we_core0;
    assign verify_addr = verify_we_core1 ? verify_addr_core1 : verify_addr_core0;
    assign verify_vector_out = verify_we_core1 ? verify_vector_out_core1 : verify_vector_out_core0;
    assign done = done_core0 && done_core1;
endmodule
