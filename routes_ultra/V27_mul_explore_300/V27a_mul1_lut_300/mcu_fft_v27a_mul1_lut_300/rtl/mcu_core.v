`include "defines.vh"

module mcu_core(
    input  wire clk,
    input  wire rst,
    output reg  [15:0] instr_addr,
    input  wire [31:0] instr,
    output wire [15:0] dmem_addr,
    output wire [15:0] dmem_wdata,
    output wire dmem_we,
    input  wire [15:0] dmem_rdata,
    output wire [7:0] test_rom_addr,
    input  wire [15:0] test_vector_in,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire first_test_rom_read,
    output wire last_verify_ram_write,
    output reg  done
);
    reg [31:0] instr_id;

    wire [3:0] opcode_id;
    wire [3:0] rd_id;
    wire [3:0] rs1_id;
    wire [3:0] rs2_id;
    wire [15:0] imm16_id;
    wire [31:0] imm32_id;

    wire signed [24:0] rf_rdata1;
    wire signed [24:0] rf_rdata2;
    wire signed [24:0] operand1_id;
    wire signed [24:0] operand2_id;

    wire ctrl_reg_we_id;
    wire ctrl_mem_read_id;
    wire ctrl_mem_write_id;
    wire ctrl_branch_id;
    wire ctrl_link_id;
    wire ctrl_cmp_en_id;
    wire ctrl_halt_id;

    reg ex_valid;
    reg [3:0] ex_opcode;
    reg [3:0] ex_rd;
    reg [15:0] ex_imm16;
    reg [31:0] ex_imm32;
    reg signed [24:0] ex_op1;
    reg signed [24:0] ex_op2;
    reg [15:0] ex_pc;
    reg ex_reg_we;
    reg ex_mem_read;
    reg ex_mem_write;
    reg ex_link;
    reg ex_cmp_en;
    reg ex_halt;

    reg wb_valid;
    reg wb_we;
    reg [3:0] wb_waddr;
    reg signed [24:0] wb_wdata;

    reg z_flag;

    wire [7:0] ex_mem_offset8;
    wire [4:0] ex_mem_offset5;
    wire [1:0] ex_mem_region;
    wire ex_is_test_rom;
    wire ex_is_verify_ram;
    wire signed [24:0] test_rom_read_data;
    wire signed [24:0] internal_read_data;
    wire signed [24:0] alu_fast_y;
    wire ex_forward_can_bypass;
    wire [3:0] ex_forward_rd_waddr;
    wire signed [24:0] ex_forward_wdata;
    wire ex_fwd_rs1_hit;
    wire ex_fwd_rs2_hit;
    wire wb_fwd_rs1_hit;
    wire wb_fwd_rs2_hit;
    wire cmp_zero_ex;
    wire take_branch_ex;

    reg mul_busy;
    reg [3:0] mul_count;
    reg [33:0] mul_acc;
    reg [33:0] mul_multiplicand;
    reg [7:0] mul_multiplier;
    reg mul_neg;
    reg [3:0] mul_waddr;
    reg mul_final;

    wire signed [25:0] ex_add = ex_op1 + ex_op2;
    wire signed [25:0] ex_sub = ex_op1 - ex_op2;
    wire [25:0] ex_abs_a = ex_op1[24] ? (~{ex_op1[24], ex_op1} + 26'd1) : {ex_op1[24], ex_op1};
    wire [7:0] ex_abs_b = ex_op2[7] ? (~ex_op2[7:0] + 8'd1) : ex_op2[7:0];
    wire [33:0] ex_mul_base = {8'd0, ex_abs_a};
    wire [33:0] ex_mul_pp0 = ex_abs_b[0] ? ex_mul_base        : 34'd0;
    wire [33:0] ex_mul_pp1 = ex_abs_b[1] ? (ex_mul_base << 1) : 34'd0;
    wire [33:0] ex_mul_pp2 = ex_abs_b[2] ? (ex_mul_base << 2) : 34'd0;
    wire [33:0] ex_mul_pp3 = ex_abs_b[3] ? (ex_mul_base << 3) : 34'd0;
    wire [33:0] ex_mul_pp4 = ex_abs_b[4] ? (ex_mul_base << 4) : 34'd0;
    wire [33:0] ex_mul_pp5 = ex_abs_b[5] ? (ex_mul_base << 5) : 34'd0;
    wire [33:0] ex_mul_pp6 = ex_abs_b[6] ? (ex_mul_base << 6) : 34'd0;
    wire [33:0] ex_mul_pp7 = ex_abs_b[7] ? (ex_mul_base << 7) : 34'd0;
    wire [33:0] ex_mul_sum01 = ex_mul_pp0 + ex_mul_pp1;
    wire [33:0] ex_mul_sum23 = ex_mul_pp2 + ex_mul_pp3;
    wire [33:0] ex_mul_sum45 = ex_mul_pp4 + ex_mul_pp5;
    wire [33:0] ex_mul_sum67 = ex_mul_pp6 + ex_mul_pp7;
    wire [33:0] ex_mul_sum03 = ex_mul_sum01 + ex_mul_sum23;
    wire [33:0] ex_mul_sum47 = ex_mul_sum45 + ex_mul_sum67;
    wire [33:0] ex_mul_mag = ex_mul_sum03 + ex_mul_sum47;
    wire signed [33:0] ex_mul_signed_mag = (ex_op1[24] ^ ex_op2[7]) ? -$signed(ex_mul_mag) : $signed(ex_mul_mag);
    wire signed [24:0] ex_mul_result_q7 = (ex_mul_signed_mag >>> 7);
    wire [33:0] mul_x1 = mul_multiplicand;
    wire [33:0] mul_x2 = mul_multiplicand << 1;
    wire [33:0] mul_x4 = mul_multiplicand << 2;
    wire [33:0] mul_x8 = mul_multiplicand << 3;
    wire [33:0] mul_addend =
        (mul_multiplier[0] ? mul_x1 : 34'd0) +
        (mul_multiplier[1] ? mul_x2 : 34'd0) +
        (mul_multiplier[2] ? mul_x4 : 34'd0) +
        (mul_multiplier[3] ? mul_x8 : 34'd0);
    wire [33:0] mul_acc_next = mul_acc + mul_addend;
    wire signed [33:0] mul_signed_mag = mul_neg ? -$signed(mul_acc) : $signed(mul_acc);
    wire signed [24:0] mul_result_q7 = (mul_signed_mag >>> 7);

    wire id_uses_rs1 =
        (opcode_id == `OP_ADD)  || (opcode_id == `OP_SUB) || (opcode_id == `OP_AND) ||
        (opcode_id == `OP_OR)   || (opcode_id == `OP_MUL) || (opcode_id == `OP_MOVR) ||
        (opcode_id == `OP_LDR)  || (opcode_id == `OP_STR) || (opcode_id == `OP_CMP);
    wire id_uses_rs2 =
        (opcode_id == `OP_ADD)  || (opcode_id == `OP_SUB) || (opcode_id == `OP_AND) ||
        (opcode_id == `OP_OR)   || (opcode_id == `OP_MUL) || (opcode_id == `OP_STR) ||
        (opcode_id == `OP_CMP);
    wire ex_mul_will_write = ex_valid && (ex_opcode == `OP_MUL);
    wire ex_load_will_write = ex_valid && (ex_opcode == `OP_LDR);
    wire ex_pending_slow_write = ex_mul_will_write || ex_load_will_write;
    wire raw_hazard_ex_rs1 = id_uses_rs1 && (rs1_id == ex_rd);
    wire raw_hazard_ex_rs2 = id_uses_rs2 && (rs2_id == ex_rd);
    wire raw_hazard_ex = ex_pending_slow_write && (raw_hazard_ex_rs1 || raw_hazard_ex_rs2);
    wire stall_id = raw_hazard_ex || mul_busy || mul_final;

    decoder u_decoder(
        .instr(instr_id),
        .opcode(opcode_id),
        .rd(rd_id),
        .rs1(rs1_id),
        .rs2(rs2_id),
        .imm16(imm16_id),
        .imm32(imm32_id)
    );

    control_unit u_control(
        .opcode(opcode_id),
        .reg_we(ctrl_reg_we_id),
        .mem_read(ctrl_mem_read_id),
        .mem_write(ctrl_mem_write_id),
        .branch(ctrl_branch_id),
        .link(ctrl_link_id),
        .cmp_en(ctrl_cmp_en_id),
        .halt(ctrl_halt_id)
    );

    reg_file u_reg_file(
        .clk(clk),
        .rst(rst),
        .raddr1(rs1_id),
        .raddr2(rs2_id),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .we(wb_valid && wb_we && !done),
        .waddr(wb_waddr),
        .wdata(wb_wdata)
    );

    assign ex_fwd_rs1_hit = ex_forward_can_bypass && (ex_forward_rd_waddr == rs1_id);
    assign ex_fwd_rs2_hit = ex_forward_can_bypass && (ex_forward_rd_waddr == rs2_id);
    assign wb_fwd_rs1_hit = wb_valid && wb_we && (wb_waddr == rs1_id);
    assign wb_fwd_rs2_hit = wb_valid && wb_we && (wb_waddr == rs2_id);

    assign operand1_id = ex_fwd_rs1_hit ? ex_forward_wdata :
                         wb_fwd_rs1_hit ? wb_wdata :
                         rf_rdata1;
    assign operand2_id = ex_fwd_rs2_hit ? ex_forward_wdata :
                         wb_fwd_rs2_hit ? wb_wdata :
                         rf_rdata2;

    assign ex_mem_offset8 = ex_op1[7:0] + ex_imm16[7:0];
    assign ex_mem_offset5 = ex_mem_offset8[4:0];
    assign ex_mem_region =
        (ex_op1[15:8] == 8'h10) ? `MEM_REGION_TEST :
        (ex_op1[15:8] == 8'h20) ? `MEM_REGION_VERIFY :
                                  `MEM_REGION_DATA;
    assign ex_is_test_rom = (ex_mem_region == `MEM_REGION_TEST);
    assign ex_is_verify_ram = (ex_mem_region == `MEM_REGION_VERIFY);

    assign dmem_addr = {8'd0, ex_mem_offset8};
    assign dmem_wdata = ex_op2[15:0];
    assign dmem_we = ex_valid && ex_mem_write && (ex_mem_region == `MEM_REGION_DATA) && !done;
    assign internal_read_data = {{9{dmem_rdata[15]}}, dmem_rdata};

    ext_test_rom_if u_ext_test_rom_if(
        .is_test_rom(ex_is_test_rom),
        .test_offset(ex_mem_offset8),
        .mem_read(ex_valid && ex_mem_read && !done),
        .test_vector_in(test_vector_in),
        .test_rom_addr(test_rom_addr),
        .read_data(test_rom_read_data),
        .first_read_pulse(first_test_rom_read)
    );

    verify_ram_if u_verify_ram_if(
        .is_verify_ram(ex_is_verify_ram),
        .verify_offset(ex_mem_offset5),
        .mem_write(ex_valid && ex_mem_write && !done),
        .write_data(ex_op2),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .last_write_pulse(last_verify_ram_write)
    );

    assign alu_fast_y =
        (ex_opcode == `OP_SUB)  ? ex_sub[24:0] :
        (ex_opcode == `OP_AND)  ? (ex_op1 & ex_op2) :
        (ex_opcode == `OP_OR)   ? (ex_op1 | ex_op2) :
        (ex_opcode == `OP_MOVR) ? ex_op1 :
                                  ex_add[24:0];
    assign ex_forward_can_bypass = ex_valid && ex_reg_we && !ex_mul_will_write && !ex_load_will_write;
    assign ex_forward_rd_waddr = ex_link ? 4'd14 : ex_rd;
    assign ex_forward_wdata =
        (ex_opcode == `OP_MOVI) ? ex_imm32[24:0] :
        (ex_opcode == `OP_BL)   ? ({9'd0, ex_pc} + 25'd1) :
                                  alu_fast_y;
    assign cmp_zero_ex = (ex_op1[24:0] == ex_op2[24:0]);
    assign take_branch_ex =
        ex_valid &&
        ((ex_opcode == `OP_B) ||
         (ex_opcode == `OP_BL) ||
         ((ex_opcode == `OP_BEQ) && z_flag) ||
         ((ex_opcode == `OP_BNE) && !z_flag));

    always @(posedge clk) begin
        if (rst) begin
            instr_addr <= 16'd0;
            instr_id <= {`OP_NOP, 28'd0};
            ex_valid <= 1'b0;
            ex_opcode <= `OP_NOP;
            ex_rd <= 4'd0;
            ex_imm16 <= 16'd0;
            ex_imm32 <= 32'd0;
            ex_op1 <= 25'sd0;
            ex_op2 <= 25'sd0;
            ex_pc <= 16'd0;
            ex_reg_we <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_link <= 1'b0;
            ex_cmp_en <= 1'b0;
            ex_halt <= 1'b0;
            wb_valid <= 1'b0;
            wb_we <= 1'b0;
            wb_waddr <= 4'd0;
            wb_wdata <= 25'sd0;
            z_flag <= 1'b0;
            done <= 1'b0;
            mul_busy <= 1'b0;
            mul_count <= 4'd0;
            mul_acc <= 34'd0;
            mul_multiplicand <= 34'd0;
            mul_multiplier <= 8'd0;
            mul_neg <= 1'b0;
            mul_waddr <= 4'd0;
            mul_final <= 1'b0;
        end else if (!done) begin
            wb_valid <= 1'b0;
            wb_we <= 1'b0;
            wb_waddr <= 4'd0;
            wb_wdata <= 25'sd0;

            if (mul_final) begin
                wb_valid <= 1'b1;
                wb_we <= 1'b1;
                wb_waddr <= mul_waddr;
                wb_wdata <= mul_result_q7;
                mul_final <= 1'b0;
            end else if (mul_busy) begin
                mul_acc <= mul_acc_next;
                mul_multiplicand <= mul_multiplicand << 4;
                mul_multiplier <= {4'b0000, mul_multiplier[7:4]};
                if (mul_count == 4'd1) begin
                    mul_busy <= 1'b0;
                    mul_final <= 1'b1;
                end else begin
                    mul_count <= mul_count + 4'd1;
                end
            end else if (ex_valid) begin
                wb_valid <= ex_reg_we;
                wb_we <= ex_reg_we;
                wb_waddr <= ex_link ? 4'd14 : ex_rd;
                if (ex_opcode == `OP_MOVI)
                    wb_wdata <= ex_imm32[24:0];
                else if (ex_opcode == `OP_MUL)
                    wb_wdata <= ex_mul_result_q7;
                else if (ex_opcode == `OP_LDR)
                    wb_wdata <= ex_is_test_rom ? test_rom_read_data : internal_read_data;
                else if (ex_opcode == `OP_BL)
                    wb_wdata <= {9'd0, ex_pc} + 25'd1;
                else
                    wb_wdata <= alu_fast_y;

                if (ex_cmp_en)
                    z_flag <= cmp_zero_ex;
                if (ex_halt)
                    done <= 1'b1;
            end

            if (take_branch_ex) begin
                instr_addr <= ex_imm16;
                instr_id <= {`OP_NOP, 28'd0};
                ex_valid <= 1'b0;
            end else if (stall_id) begin
                ex_valid <= 1'b0;
            end else begin
                instr_addr <= instr_addr + 16'd1;
                instr_id <= instr;
                ex_valid <= (opcode_id != `OP_NOP);
                ex_opcode <= opcode_id;
                ex_rd <= rd_id;
                ex_imm16 <= imm16_id;
                ex_imm32 <= imm32_id;
                ex_op1 <= operand1_id;
                ex_op2 <= operand2_id;
                ex_pc <= instr_addr;
                ex_reg_we <= ctrl_reg_we_id;
                ex_mem_read <= ctrl_mem_read_id;
                ex_mem_write <= ctrl_mem_write_id;
                ex_link <= ctrl_link_id;
                ex_cmp_en <= ctrl_cmp_en_id;
                ex_halt <= ctrl_halt_id;
            end
        end
    end
endmodule
