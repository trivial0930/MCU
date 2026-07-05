module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [7:0] test_rom_addr0,
    output wire [7:0] test_rom_addr1,
    output wire [7:0] test_rom_addr2,
    output wire [7:0] test_rom_addr3,
    output wire [7:0] test_rom_addr4,
    output wire [7:0] test_rom_addr5,
    output wire [7:0] test_rom_addr6,
    output wire [7:0] test_rom_addr7,
    input  wire [15:0] test_vector_in0,
    input  wire [15:0] test_vector_in1,
    input  wire [15:0] test_vector_in2,
    input  wire [15:0] test_vector_in3,
    input  wire [15:0] test_vector_in4,
    input  wire [15:0] test_vector_in5,
    input  wire [15:0] test_vector_in6,
    input  wire [15:0] test_vector_in7,
    output wire [4:0] verify_addr0,
    output wire [4:0] verify_addr1,
    output wire [4:0] verify_addr2,
    output wire [4:0] verify_addr3,
    output wire [4:0] verify_addr4,
    output wire [4:0] verify_addr5,
    output wire [4:0] verify_addr6,
    output wire [4:0] verify_addr7,
    output wire [15:0] verify_vector_out0,
    output wire [15:0] verify_vector_out1,
    output wire [15:0] verify_vector_out2,
    output wire [15:0] verify_vector_out3,
    output wire [15:0] verify_vector_out4,
    output wire [15:0] verify_vector_out5,
    output wire [15:0] verify_vector_out6,
    output wire [15:0] verify_vector_out7,
    output wire verify_we0,
    output wire verify_we1,
    output wire verify_we2,
    output wire verify_we3,
    output wire verify_we4,
    output wire verify_we5,
    output wire verify_we6,
    output wire verify_we7,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [15:0] verify_done_mask,
    output wire [19:0] cnt_test,
    output wire done
);
    wire [15:0] instr_addr [0:7];
    wire [31:0] instr [0:7];
    wire [15:0] dmem_addr [0:7];
    wire [15:0] dmem_wdata [0:7];
    wire dmem_we [0:7];
    wire [15:0] dmem_rdata [0:7];
    wire [7:0] test_rom_addr_i [0:7];
    wire [15:0] test_vector_in_i [0:7];
    wire [4:0] verify_addr_i [0:7];
    wire [15:0] verify_vector_out_i [0:7];
    wire [7:0] verify_we_i;
    wire [7:0] first_test_rom_read_i;
    wire [7:0] last_verify_ram_write_i;
    wire [7:0] done_core_i;
    reg [15:0] done_mask_q;
    reg [7:0] owner_seen_q;
    reg [7:0] owner_done_q;

    assign test_rom_addr0 = test_rom_addr_i[0];
    assign test_rom_addr1 = test_rom_addr_i[1];
    assign test_rom_addr2 = test_rom_addr_i[2];
    assign test_rom_addr3 = test_rom_addr_i[3];
    assign test_rom_addr4 = test_rom_addr_i[4];
    assign test_rom_addr5 = test_rom_addr_i[5];
    assign test_rom_addr6 = test_rom_addr_i[6];
    assign test_rom_addr7 = test_rom_addr_i[7];

    assign test_vector_in_i[0] = test_vector_in0;
    assign test_vector_in_i[1] = test_vector_in1;
    assign test_vector_in_i[2] = test_vector_in2;
    assign test_vector_in_i[3] = test_vector_in3;
    assign test_vector_in_i[4] = test_vector_in4;
    assign test_vector_in_i[5] = test_vector_in5;
    assign test_vector_in_i[6] = test_vector_in6;
    assign test_vector_in_i[7] = test_vector_in7;

    assign verify_addr0 = verify_addr_i[0];
    assign verify_addr1 = verify_addr_i[1];
    assign verify_addr2 = verify_addr_i[2];
    assign verify_addr3 = verify_addr_i[3];
    assign verify_addr4 = verify_addr_i[4];
    assign verify_addr5 = verify_addr_i[5];
    assign verify_addr6 = verify_addr_i[6];
    assign verify_addr7 = verify_addr_i[7];

    assign verify_vector_out0 = verify_vector_out_i[0];
    assign verify_vector_out1 = verify_vector_out_i[1];
    assign verify_vector_out2 = verify_vector_out_i[2];
    assign verify_vector_out3 = verify_vector_out_i[3];
    assign verify_vector_out4 = verify_vector_out_i[4];
    assign verify_vector_out5 = verify_vector_out_i[5];
    assign verify_vector_out6 = verify_vector_out_i[6];
    assign verify_vector_out7 = verify_vector_out_i[7];

    assign verify_we0 = verify_we_i[0];
    assign verify_we1 = verify_we_i[1];
    assign verify_we2 = verify_we_i[2];
    assign verify_we3 = verify_we_i[3];
    assign verify_we4 = verify_we_i[4];
    assign verify_we5 = verify_we_i[5];
    assign verify_we6 = verify_we_i[6];
    assign verify_we7 = verify_we_i[7];

    instr_rom #(.INIT_FILE("mem/instr_fft8.mem")) u_instr_rom_core0(
        .addr(instr_addr[0]),
        .instr(instr[0])
    );

    instr_rom #(.INIT_FILE("mem/instr_core1.mem")) u_instr_rom_core1(
        .addr(instr_addr[1]),
        .instr(instr[1])
    );

    instr_rom #(.INIT_FILE("mem/instr_core2.mem")) u_instr_rom_core2(
        .addr(instr_addr[2]),
        .instr(instr[2])
    );

    instr_rom #(.INIT_FILE("mem/instr_core3.mem")) u_instr_rom_core3(
        .addr(instr_addr[3]),
        .instr(instr[3])
    );

    instr_rom #(.INIT_FILE("mem/instr_core4.mem")) u_instr_rom_core4(
        .addr(instr_addr[4]),
        .instr(instr[4])
    );

    instr_rom #(.INIT_FILE("mem/instr_core5.mem")) u_instr_rom_core5(
        .addr(instr_addr[5]),
        .instr(instr[5])
    );

    instr_rom #(.INIT_FILE("mem/instr_core6.mem")) u_instr_rom_core6(
        .addr(instr_addr[6]),
        .instr(instr[6])
    );

    instr_rom #(.INIT_FILE("mem/instr_core7.mem")) u_instr_rom_core7(
        .addr(instr_addr[7]),
        .instr(instr[7])
    );

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_mcu_core
            assign dmem_rdata[gi] = 16'd0;

            mcu_core u_mcu_core(
                .clk(clk),
                .rst(rst),
                .instr_addr(instr_addr[gi]),
                .instr(instr[gi]),
                .dmem_addr(dmem_addr[gi]),
                .dmem_wdata(dmem_wdata[gi]),
                .dmem_we(dmem_we[gi]),
                .dmem_rdata(dmem_rdata[gi]),
                .test_rom_addr(test_rom_addr_i[gi]),
                .test_vector_in(test_vector_in_i[gi]),
                .verify_addr(verify_addr_i[gi]),
                .verify_vector_out(verify_vector_out_i[gi]),
                .verify_we(verify_we_i[gi]),
                .first_test_rom_read(first_test_rom_read_i[gi]),
                .last_verify_ram_write(last_verify_ram_write_i[gi]),
                .done(done_core_i[gi])
            );
        end
    endgenerate

    wire [15:0] verify_bit0 = verify_we_i[0] ? (16'h0001 << verify_addr_i[0][3:0]) : 16'h0000;
    wire [15:0] verify_bit1 = verify_we_i[1] ? (16'h0001 << verify_addr_i[1][3:0]) : 16'h0000;
    wire [15:0] verify_bit2 = verify_we_i[2] ? (16'h0001 << verify_addr_i[2][3:0]) : 16'h0000;
    wire [15:0] verify_bit3 = verify_we_i[3] ? (16'h0001 << verify_addr_i[3][3:0]) : 16'h0000;
    wire [15:0] verify_bit4 = verify_we_i[4] ? (16'h0001 << verify_addr_i[4][3:0]) : 16'h0000;
    wire [15:0] verify_bit5 = verify_we_i[5] ? (16'h0001 << verify_addr_i[5][3:0]) : 16'h0000;
    wire [15:0] verify_bit6 = verify_we_i[6] ? (16'h0001 << verify_addr_i[6][3:0]) : 16'h0000;
    wire [15:0] verify_bit7 = verify_we_i[7] ? (16'h0001 << verify_addr_i[7][3:0]) : 16'h0000;
    wire [15:0] done_mask_next =
        done_mask_q | verify_bit0 | verify_bit1 | verify_bit2 | verify_bit3 |
        verify_bit4 | verify_bit5 | verify_bit6 | verify_bit7;
    wire [7:0] owner_seen_next = owner_seen_q | verify_we_i;
    wire [7:0] owner_done_next = owner_done_q | (verify_we_i & owner_seen_q);
    wire verify_complete_pulse_raw = (owner_done_next == 8'hff) && (owner_done_q != 8'hff);

    cnt_test_unit u_cnt_test(
        .clk(clk),
        .rst(rst),
        .start_pulse(|first_test_rom_read_i),
        .stop_pulse(verify_complete_pulse_raw),
        .cnt_test(cnt_test)
    );

    always @(posedge clk) begin
        if (rst) begin
            done_mask_q <= 16'h0000;
            owner_seen_q <= 8'h00;
            owner_done_q <= 8'h00;
        end else begin
            done_mask_q <= done_mask_next;
            owner_seen_q <= owner_seen_next;
            owner_done_q <= owner_done_next;
        end
    end

    assign verify_done_mask = done_mask_q;
    assign verify_we = |verify_we_i;
    assign verify_addr =
        verify_we_i[7] ? verify_addr_i[7] :
        verify_we_i[6] ? verify_addr_i[6] :
        verify_we_i[5] ? verify_addr_i[5] :
        verify_we_i[4] ? verify_addr_i[4] :
        verify_we_i[3] ? verify_addr_i[3] :
        verify_we_i[2] ? verify_addr_i[2] :
        verify_we_i[1] ? verify_addr_i[1] :
                         verify_addr_i[0];
    assign verify_vector_out =
        verify_we_i[7] ? verify_vector_out_i[7] :
        verify_we_i[6] ? verify_vector_out_i[6] :
        verify_we_i[5] ? verify_vector_out_i[5] :
        verify_we_i[4] ? verify_vector_out_i[4] :
        verify_we_i[3] ? verify_vector_out_i[3] :
        verify_we_i[2] ? verify_vector_out_i[2] :
        verify_we_i[1] ? verify_vector_out_i[1] :
                         verify_vector_out_i[0];

    assign done = &done_core_i;
endmodule
