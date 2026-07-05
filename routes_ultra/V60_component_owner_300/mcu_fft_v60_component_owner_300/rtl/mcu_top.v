module mcu_top(
    input  wire clk,
    input  wire rst,
    output wire [127:0] test_rom_addr_bus,
    input  wire [255:0] test_vector_in_bus,
    output wire [79:0] verify_addr_bus,
    output wire [255:0] verify_vector_out_bus,
    output wire [15:0] verify_we_bus,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire [15:0] verify_done_mask,
    output wire [19:0] cnt_test,
    output wire done
`ifdef ENABLE_ILA
    ,
    output wire [15:0] verify_done_mask_next_dbg,
    output wire fast_stop_pulse_dbg
`endif
);
    wire [15:0] instr_addr [0:15];
    wire [31:0] instr [0:15];
    wire [15:0] dmem_addr [0:15];
    wire [15:0] dmem_wdata [0:15];
    wire dmem_we [0:15];
    wire [15:0] dmem_rdata [0:15];
    wire [7:0] test_rom_addr_i [0:15];
    wire [15:0] test_vector_in_i [0:15];
    wire [4:0] verify_addr_i [0:15];
    wire [15:0] verify_vector_out_i [0:15];
    wire [15:0] verify_we_i;
    wire [15:0] first_test_rom_read_i;
    wire [15:0] last_verify_ram_write_i;
    wire [15:0] done_core_i;
    reg [15:0] done_mask_q;
    reg verify_complete_q;
    reg [4:0] verify_addr_r;
    reg [15:0] verify_vector_out_r;
    integer pi;

    instr_rom #(.INIT_FILE("mem/instr_core0.mem")) u_instr_rom_core0(.addr(instr_addr[0]), .instr(instr[0]));
    instr_rom #(.INIT_FILE("mem/instr_core1.mem")) u_instr_rom_core1(.addr(instr_addr[1]), .instr(instr[1]));
    instr_rom #(.INIT_FILE("mem/instr_core2.mem")) u_instr_rom_core2(.addr(instr_addr[2]), .instr(instr[2]));
    instr_rom #(.INIT_FILE("mem/instr_core3.mem")) u_instr_rom_core3(.addr(instr_addr[3]), .instr(instr[3]));
    instr_rom #(.INIT_FILE("mem/instr_core4.mem")) u_instr_rom_core4(.addr(instr_addr[4]), .instr(instr[4]));
    instr_rom #(.INIT_FILE("mem/instr_core5.mem")) u_instr_rom_core5(.addr(instr_addr[5]), .instr(instr[5]));
    instr_rom #(.INIT_FILE("mem/instr_core6.mem")) u_instr_rom_core6(.addr(instr_addr[6]), .instr(instr[6]));
    instr_rom #(.INIT_FILE("mem/instr_core7.mem")) u_instr_rom_core7(.addr(instr_addr[7]), .instr(instr[7]));
    instr_rom #(.INIT_FILE("mem/instr_core8.mem")) u_instr_rom_core8(.addr(instr_addr[8]), .instr(instr[8]));
    instr_rom #(.INIT_FILE("mem/instr_core9.mem")) u_instr_rom_core9(.addr(instr_addr[9]), .instr(instr[9]));
    instr_rom #(.INIT_FILE("mem/instr_core10.mem")) u_instr_rom_core10(.addr(instr_addr[10]), .instr(instr[10]));
    instr_rom #(.INIT_FILE("mem/instr_core11.mem")) u_instr_rom_core11(.addr(instr_addr[11]), .instr(instr[11]));
    instr_rom #(.INIT_FILE("mem/instr_core12.mem")) u_instr_rom_core12(.addr(instr_addr[12]), .instr(instr[12]));
    instr_rom #(.INIT_FILE("mem/instr_core13.mem")) u_instr_rom_core13(.addr(instr_addr[13]), .instr(instr[13]));
    instr_rom #(.INIT_FILE("mem/instr_core14.mem")) u_instr_rom_core14(.addr(instr_addr[14]), .instr(instr[14]));
    instr_rom #(.INIT_FILE("mem/instr_core15.mem")) u_instr_rom_core15(.addr(instr_addr[15]), .instr(instr[15]));

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_mcu_core
            assign test_rom_addr_bus[gi*8 +: 8] = test_rom_addr_i[gi];
            assign test_vector_in_i[gi] = test_vector_in_bus[gi*16 +: 16];
            assign verify_addr_bus[gi*5 +: 5] = verify_addr_i[gi];
            assign verify_vector_out_bus[gi*16 +: 16] = verify_vector_out_i[gi];
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

    wire verify_hit0 = verify_we_i[0] && (verify_addr_i[0][3:0] == 4'd0);
    wire verify_hit1 = verify_we_i[1] && (verify_addr_i[1][3:0] == 4'd1);
    wire verify_hit2 = verify_we_i[2] && (verify_addr_i[2][3:0] == 4'd2);
    wire verify_hit3 = verify_we_i[3] && (verify_addr_i[3][3:0] == 4'd3);
    wire verify_hit4 = verify_we_i[4] && (verify_addr_i[4][3:0] == 4'd4);
    wire verify_hit5 = verify_we_i[5] && (verify_addr_i[5][3:0] == 4'd5);
    wire verify_hit6 = verify_we_i[6] && (verify_addr_i[6][3:0] == 4'd6);
    wire verify_hit7 = verify_we_i[7] && (verify_addr_i[7][3:0] == 4'd7);
    wire verify_hit8 = verify_we_i[8] && (verify_addr_i[8][3:0] == 4'd8);
    wire verify_hit9 = verify_we_i[9] && (verify_addr_i[9][3:0] == 4'd9);
    wire verify_hit10 = verify_we_i[10] && (verify_addr_i[10][3:0] == 4'd10);
    wire verify_hit11 = verify_we_i[11] && (verify_addr_i[11][3:0] == 4'd11);
    wire verify_hit12 = verify_we_i[12] && (verify_addr_i[12][3:0] == 4'd12);
    wire verify_hit13 = verify_we_i[13] && (verify_addr_i[13][3:0] == 4'd13);
    wire verify_hit14 = verify_we_i[14] && (verify_addr_i[14][3:0] == 4'd14);
    wire verify_hit15 = verify_we_i[15] && (verify_addr_i[15][3:0] == 4'd15);
    wire [15:0] verify_hit_mask = {
        verify_hit15, verify_hit14, verify_hit13, verify_hit12,
        verify_hit11, verify_hit10, verify_hit9, verify_hit8,
        verify_hit7, verify_hit6, verify_hit5, verify_hit4,
        verify_hit3, verify_hit2, verify_hit1, verify_hit0
    };
    wire [15:0] done_mask_next = done_mask_q | verify_hit_mask;
    wire verify_complete_next = (done_mask_next == 16'hffff);

    cnt_test_unit u_cnt_test(
        .clk(clk),
        .rst(rst),
        .start_pulse(|first_test_rom_read_i),
        .stop_pulse(verify_complete_q),
        .cnt_test(cnt_test)
    );

    always @(posedge clk) begin
        if (rst) begin
            done_mask_q <= 16'h0000;
            verify_complete_q <= 1'b0;
        end else begin
            done_mask_q <= done_mask_next;
            verify_complete_q <= verify_complete_next;
        end
    end

    always @(*) begin
        verify_addr_r = 5'd0;
        verify_vector_out_r = 16'd0;
        for (pi = 0; pi < 16; pi = pi + 1) begin
            if (verify_we_i[pi]) begin
                verify_addr_r = verify_addr_i[pi];
                verify_vector_out_r = verify_vector_out_i[pi];
            end
        end
    end

    assign verify_done_mask = done_mask_q;
`ifdef ENABLE_ILA
    assign verify_done_mask_next_dbg = done_mask_next;
    assign fast_stop_pulse_dbg = verify_complete_q;
`endif
    assign verify_we_bus = verify_we_i;
    assign verify_we = |verify_we_i;
    assign verify_addr = verify_addr_r;
    assign verify_vector_out = verify_vector_out_r;
    assign done = &done_core_i;
endmodule
