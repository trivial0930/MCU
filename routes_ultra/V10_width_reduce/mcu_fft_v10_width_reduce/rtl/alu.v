`include "defines.vh"

module alu(
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [31:0] y,
    output wire zero,
    output wire negative
);
    wire signed [24:0] a25 = a[24:0];
    wire signed [24:0] b25 = b[24:0];
    wire signed [25:0] add25 = a25 + b25;
    wire signed [25:0] sub25 = a25 - b25;
    wire signed [24:0] and25 = a25 & b25;
    wire signed [24:0] or25 = a25 | b25;
    wire signed [24:0] mul_data_q12 = a[24:0];
    wire signed [7:0] mul_coeff_q7 = b[7:0];
    wire signed [32:0] mul_q7_full = mul_data_q12 * mul_coeff_q7;
    wire signed [24:0] mul_q7_narrow = mul_q7_full >>> 7;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = {{6{add25[25]}}, add25};
            `ALU_SUB:     y = {{6{sub25[25]}}, sub25};
            `ALU_AND:     y = {{7{and25[24]}}, and25};
            `ALU_OR:      y = {{7{or25[24]}}, or25};
            `ALU_MOV:     y = {{7{b25[24]}}, b25};
            `ALU_MUL_Q7:  y = {{7{mul_q7_narrow[24]}}, mul_q7_narrow};
            default:      y = 32'sd0;
        endcase
    end

    assign zero = (y == 32'sd0);
    assign negative = y[31];
endmodule
