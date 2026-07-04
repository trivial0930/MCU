`include "defines.vh"

module control_unit(
    input  wire [3:0] opcode,
    output reg  reg_we,
    output reg  mem_read,
    output reg  mem_write,
    output reg  branch,
    output reg  link,
    output reg  cmp_en,
    output reg  halt
);
    always @(*) begin
        reg_we = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        link = 1'b0;
        cmp_en = 1'b0;
        halt = 1'b0;

        case (opcode)
            `OP_ADD, `OP_SUB, `OP_AND, `OP_OR, `OP_MOVI, `OP_MOVR, `OP_MUL:
                reg_we = 1'b1;
            `OP_LDR: begin
                reg_we = 1'b1;
                mem_read = 1'b1;
            end
            `OP_STR:
                mem_write = 1'b1;
            `OP_B: begin
                branch = 1'b1;
            end
            `OP_BL: begin
                branch = 1'b1;
                link = 1'b1;
                reg_we = 1'b1;
            end
            `OP_CMP:
                cmp_en = 1'b1;
            `OP_BEQ, `OP_BNE:
                branch = 1'b1;
            `OP_HALT:
                halt = 1'b1;
            default: begin
            end
        endcase
    end
endmodule
