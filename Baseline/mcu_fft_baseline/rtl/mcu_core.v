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
    output wire [4:0] test_rom_addr,
    input  wire [15:0] test_vector_in,
    output wire [4:0] verify_addr,
    output wire [15:0] verify_vector_out,
    output wire verify_we,
    output wire first_test_rom_read,
    output wire last_verify_ram_write,
    output reg  done
);
    wire [3:0] opcode;
    wire [3:0] rd;
    wire [3:0] rs1;
    wire [3:0] rs2;
    wire [15:0] imm16;
    wire [31:0] imm32;

    wire [31:0] rdata1;
    wire [31:0] rdata2;
    reg  [31:0] reg_wdata;
    reg  [3:0] reg_waddr;
    reg  reg_we_final;

    reg z_flag;
    reg n_flag;

    wire ctrl_reg_we;
    wire ctrl_mem_read;
    wire ctrl_mem_write;
    wire ctrl_branch;
    wire ctrl_link;
    wire ctrl_cmp_en;
    wire ctrl_halt;

    reg [3:0] alu_op;
    reg signed [31:0] alu_a;
    reg signed [31:0] alu_b;
    wire signed [31:0] alu_y;
    wire alu_zero;
    wire alu_negative;

    wire [31:0] mem_addr;
    wire is_test_rom;
    wire [31:0] test_rom_read_data;
    wire [31:0] internal_read_data;
    wire take_branch;

    decoder u_decoder(
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm16(imm16),
        .imm32(imm32)
    );

    control_unit u_control(
        .opcode(opcode),
        .reg_we(ctrl_reg_we),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .branch(ctrl_branch),
        .link(ctrl_link),
        .cmp_en(ctrl_cmp_en),
        .halt(ctrl_halt)
    );

    reg_file u_reg_file(
        .clk(clk),
        .rst(rst),
        .raddr1(rs1),
        .raddr2(rs2),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .we(reg_we_final),
        .waddr(reg_waddr),
        .wdata(reg_wdata)
    );

    alu u_alu(
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .y(alu_y),
        .zero(alu_zero),
        .negative(alu_negative)
    );

    assign mem_addr = rdata1 + imm32;
    assign dmem_addr = mem_addr[15:0];
    assign dmem_wdata = rdata2[15:0];
    assign dmem_we = ctrl_mem_write && !verify_we && !done;
    assign internal_read_data = {{16{dmem_rdata[15]}}, dmem_rdata};

    ext_test_rom_if u_ext_test_rom_if(
        .mem_addr(mem_addr),
        .mem_read(ctrl_mem_read && !done),
        .test_vector_in(test_vector_in),
        .test_rom_addr(test_rom_addr),
        .read_data(test_rom_read_data),
        .is_test_rom(is_test_rom),
        .first_read_pulse(first_test_rom_read)
    );

    verify_ram_if u_verify_ram_if(
        .mem_addr(mem_addr),
        .mem_write(ctrl_mem_write && !done),
        .write_data(rdata2),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .last_write_pulse(last_verify_ram_write)
    );

    assign take_branch =
        (opcode == `OP_B) ||
        (opcode == `OP_BL) ||
        ((opcode == `OP_BEQ) && z_flag) ||
        ((opcode == `OP_BNE) && !z_flag);

    always @(*) begin
        alu_a = rdata1;
        alu_b = rdata2;
        alu_op = `ALU_ADD;

        case (opcode)
            `OP_ADD: alu_op = `ALU_ADD;
            `OP_SUB: alu_op = `ALU_SUB;
            `OP_AND: alu_op = `ALU_AND;
            `OP_OR:  alu_op = `ALU_OR;
            `OP_MOVR: begin
                alu_op = `ALU_MOV;
                alu_b = rdata1;
            end
            `OP_MUL: alu_op = `ALU_MUL_Q15;
            `OP_CMP: alu_op = `ALU_SUB;
            default: alu_op = `ALU_ADD;
        endcase
    end

    always @(*) begin
        reg_waddr = rd;
        reg_wdata = alu_y;
        reg_we_final = ctrl_reg_we && !done;

        case (opcode)
            `OP_MOVI: reg_wdata = imm32;
            `OP_LDR:  reg_wdata = is_test_rom ? test_rom_read_data : internal_read_data;
            `OP_BL: begin
                reg_waddr = 4'd14;
                reg_wdata = {16'd0, instr_addr} + 32'd1;
            end
            default: begin
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            instr_addr <= 16'd0;
            z_flag <= 1'b0;
            n_flag <= 1'b0;
            done <= 1'b0;
        end else if (!done) begin
            if (ctrl_cmp_en) begin
                z_flag <= alu_zero;
                n_flag <= alu_negative;
            end

            if (ctrl_halt)
                done <= 1'b1;

            if (take_branch)
                instr_addr <= imm16;
            else
                instr_addr <= instr_addr + 16'd1;
        end
    end
endmodule
