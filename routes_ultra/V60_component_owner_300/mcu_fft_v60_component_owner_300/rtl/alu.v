`include "defines.vh"

module alu(
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [31:0] y,
    output wire zero,
    output wire negative
);
    wire signed [32:0] add32 = {a[31], a} + {b[31], b};
    wire signed [32:0] sub32 = {a[31], a} - {b[31], b};
    wire signed [31:0] and32 = a & b;
    wire signed [31:0] or32 = a | b;
    wire signed [31:0] mul_data_q12 = a;
    wire signed [7:0] mul_coeff_q7 = b[7:0];
    wire signed [39:0] mul_q7_full = mul_data_q12 * mul_coeff_q7;
    wire signed [31:0] mul_q7_narrow = mul_q7_full >>> 7;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = add32[31:0];
            `ALU_SUB:     y = sub32[31:0];
            `ALU_AND:     y = and32;
            `ALU_OR:      y = or32;
            `ALU_MOV:     y = b;
            `ALU_MUL_Q7:  y = mul_q7_narrow;
            default:      y = 32'sd0;
        endcase
    end

    assign zero = (y == 32'sd0);
    assign negative = y[31];
endmodule
