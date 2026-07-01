`include "defines.vh"

module alu(
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [31:0] y,
    output wire zero,
    output wire negative
);
    wire signed [24:0] mul_data_q12 = a[24:0];
    wire signed [7:0] mul_coeff_q7 = b[7:0];
    wire signed [32:0] mul_q7_full = mul_data_q12 * mul_coeff_q7;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = a + b;
            `ALU_SUB:     y = a - b;
            `ALU_AND:     y = a & b;
            `ALU_OR:      y = a | b;
            `ALU_MOV:     y = b;
            `ALU_MUL_Q7:  y = mul_q7_full >>> 7;
            default:      y = 32'sd0;
        endcase
    end

    assign zero = (y == 32'sd0);
    assign negative = y[31];
endmodule
