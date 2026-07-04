`include "defines.vh"

module alu(
    input  wire signed [24:0] a,
    input  wire signed [24:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [24:0] y,
    output wire zero,
    output wire negative
);
    wire signed [25:0] add25 = a + b;
    wire signed [25:0] sub25 = a - b;
    wire signed [24:0] and25 = a & b;
    wire signed [24:0] or25 = a | b;
    wire signed [24:0] mul_data_q12 = a;
    wire signed [7:0] mul_coeff_q7 = b[7:0];
    wire signed [32:0] mul_q7_full = mul_data_q12 * mul_coeff_q7;
    wire signed [24:0] mul_q7_narrow = mul_q7_full >>> 7;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = add25[24:0];
            `ALU_SUB:     y = sub25[24:0];
            `ALU_AND:     y = and25;
            `ALU_OR:      y = or25;
            `ALU_MOV:     y = b;
            `ALU_MUL_Q7:  y = mul_q7_narrow;
            default:      y = 25'sd0;
        endcase
    end

    assign zero = (y == 25'sd0);
    assign negative = y[24];
endmodule
