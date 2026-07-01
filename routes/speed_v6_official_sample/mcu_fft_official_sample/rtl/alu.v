`include "defines.vh"

module alu(
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [31:0] y,
    output wire zero,
    output wire negative
);
    wire signed [63:0] mul_full = a * b;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = a + b;
            `ALU_SUB:     y = a - b;
            `ALU_AND:     y = a & b;
            `ALU_OR:      y = a | b;
            `ALU_MOV:     y = b;
            `ALU_MUL_Q7:  y = mul_full >>> 7;
            default:      y = 32'sd0;
        endcase
    end

    assign zero = (y == 32'sd0);
    assign negative = y[31];
endmodule
