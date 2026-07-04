module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [7:0] test_rom_addr0,
    output wire [7:0] test_rom_addr1,
    output wire [7:0] test_rom_addr2,
    output wire [7:0] test_rom_addr3,
    input  wire [15:0] test_vector_in0,
    input  wire [15:0] test_vector_in1,
    input  wire [15:0] test_vector_in2,
    input  wire [15:0] test_vector_in3,
    output wire [4:0] verify_addr0,
    output wire [4:0] verify_addr1,
    output wire [4:0] verify_addr2,
    output wire [4:0] verify_addr3,
    output wire [15:0] verify_vector_out0,
    output wire [15:0] verify_vector_out1,
    output wire [15:0] verify_vector_out2,
    output wire [15:0] verify_vector_out3,
    output wire verify_we0,
    output wire verify_we1,
    output wire verify_we2,
    output wire verify_we3,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [15:0] verify_done_mask,
    output wire [19:0] cnt_test,
    output wire done
);
    wire [15:0] instr_addr_core0;
    wire [15:0] instr_addr_core1;
    wire [15:0] instr_addr_core2;
    wire [15:0] instr_addr_core3;
    wire [31:0] instr_core0;
    wire [31:0] instr_core1;
    wire [31:0] instr_core2;
    wire [31:0] instr_core3;

    wire [15:0] dmem_addr_core0;
    wire [15:0] dmem_addr_core1;
    wire [15:0] dmem_addr_core2;
    wire [15:0] dmem_addr_core3;
    wire [15:0] dmem_wdata_core0;
    wire [15:0] dmem_wdata_core1;
    wire [15:0] dmem_wdata_core2;
    wire [15:0] dmem_wdata_core3;
    wire dmem_we_core0;
    wire dmem_we_core1;
    wire dmem_we_core2;
    wire dmem_we_core3;
    wire [15:0] dmem_rdata_core0;
    wire [15:0] dmem_rdata_core1;
    wire [15:0] dmem_rdata_core2;
    wire [15:0] dmem_rdata_core3;

    wire first_test_rom_read_core0;
    wire first_test_rom_read_core1;
    wire first_test_rom_read_core2;
    wire first_test_rom_read_core3;
    wire last_verify_ram_write_core0;
    wire last_verify_ram_write_core1;
    wire last_verify_ram_write_core2;
    wire last_verify_ram_write_core3;
    wire done_core0;
    wire done_core1;
    wire done_core2;
    wire done_core3;

    reg [15:0] done_mask_q;

    wire [15:0] verify_bit0 = verify_we0 ? (16'h0001 << verify_addr0[3:0]) : 16'h0000;
    wire [15:0] verify_bit1 = verify_we1 ? (16'h0001 << verify_addr1[3:0]) : 16'h0000;
    wire [15:0] verify_bit2 = verify_we2 ? (16'h0001 << verify_addr2[3:0]) : 16'h0000;
    wire [15:0] verify_bit3 = verify_we3 ? (16'h0001 << verify_addr3[3:0]) : 16'h0000;
    wire [15:0] done_mask_next = done_mask_q | verify_bit0 | verify_bit1 | verify_bit2 | verify_bit3;
    wire verify_complete_pulse = (done_mask_next == 16'hffff) && (done_mask_q != 16'hffff);

    instr_rom u_instr_rom_core0(
        .addr(instr_addr_core0),
        .instr(instr_core0)
    );

    instr_rom #(.INIT_FILE("mem/instr_core1.mem")) u_instr_rom_core1(
        .addr(instr_addr_core1),
        .instr(instr_core1)
    );

    instr_rom #(.INIT_FILE("mem/instr_core2.mem")) u_instr_rom_core2(
        .addr(instr_addr_core2),
        .instr(instr_core2)
    );

    instr_rom #(.INIT_FILE("mem/instr_core3.mem")) u_instr_rom_core3(
        .addr(instr_addr_core3),
        .instr(instr_core3)
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
        .rdata1(dmem_rdata_core1),
        .we2(1'b0),
        .addr2(dmem_addr_core2),
        .wdata2(dmem_wdata_core2),
        .rdata2(dmem_rdata_core2),
        .we3(1'b0),
        .addr3(dmem_addr_core3),
        .wdata3(dmem_wdata_core3),
        .rdata3(dmem_rdata_core3)
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
        .test_rom_addr(test_rom_addr0),
        .test_vector_in(test_vector_in0),
        .verify_addr(verify_addr0),
        .verify_vector_out(verify_vector_out0),
        .verify_we(verify_we0),
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
        .test_rom_addr(test_rom_addr1),
        .test_vector_in(test_vector_in1),
        .verify_addr(verify_addr1),
        .verify_vector_out(verify_vector_out1),
        .verify_we(verify_we1),
        .first_test_rom_read(first_test_rom_read_core1),
        .last_verify_ram_write(last_verify_ram_write_core1),
        .done(done_core1)
    );

    mcu_core u_mcu_core2(
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr_core2),
        .instr(instr_core2),
        .dmem_addr(dmem_addr_core2),
        .dmem_wdata(dmem_wdata_core2),
        .dmem_we(dmem_we_core2),
        .dmem_rdata(dmem_rdata_core2),
        .test_rom_addr(test_rom_addr2),
        .test_vector_in(test_vector_in2),
        .verify_addr(verify_addr2),
        .verify_vector_out(verify_vector_out2),
        .verify_we(verify_we2),
        .first_test_rom_read(first_test_rom_read_core2),
        .last_verify_ram_write(last_verify_ram_write_core2),
        .done(done_core2)
    );

    mcu_core u_mcu_core3(
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr_core3),
        .instr(instr_core3),
        .dmem_addr(dmem_addr_core3),
        .dmem_wdata(dmem_wdata_core3),
        .dmem_we(dmem_we_core3),
        .dmem_rdata(dmem_rdata_core3),
        .test_rom_addr(test_rom_addr3),
        .test_vector_in(test_vector_in3),
        .verify_addr(verify_addr3),
        .verify_vector_out(verify_vector_out3),
        .verify_we(verify_we3),
        .first_test_rom_read(first_test_rom_read_core3),
        .last_verify_ram_write(last_verify_ram_write_core3),
        .done(done_core3)
    );

    cnt_test_unit u_cnt_test(
        .clk(clk),
        .rst(rst),
        .start_pulse(first_test_rom_read_core0 | first_test_rom_read_core1 |
                     first_test_rom_read_core2 | first_test_rom_read_core3),
        .stop_pulse(verify_complete_pulse),
        .cnt_test(cnt_test)
    );

    always @(posedge clk) begin
        if (rst)
            done_mask_q <= 16'h0000;
        else
            done_mask_q <= done_mask_next;
    end

    assign verify_done_mask = done_mask_q;

    assign verify_we =
        verify_we3 | verify_we2 | verify_we1 | verify_we0;
    assign verify_addr =
        verify_we3 ? verify_addr3 :
        verify_we2 ? verify_addr2 :
        verify_we1 ? verify_addr1 :
                     verify_addr0;
    assign verify_vector_out =
        verify_we3 ? verify_vector_out3 :
        verify_we2 ? verify_vector_out2 :
        verify_we1 ? verify_vector_out1 :
                     verify_vector_out0;

    assign done = done_core0 && done_core1 && done_core2 && done_core3;
endmodule
