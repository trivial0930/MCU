`include "defines.vh"

module alu(
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    input  wire [3:0] alu_op,
    output reg  signed [31:0] y,
    output wire zero,
    output wire negative
);
    wire signed [39:0] mul_data_ext = {{8{a[31]}}, a};
    wire signed [31:0] add_ab = a + b;
    wire signed [31:0] sub_ab = a - b;
    wire signed [31:0] neg_sum_ab = -(a + b);
    wire signed [39:0] madd91_data_ext = {{8{add_ab[31]}}, add_ab};
    wire signed [39:0] msub91_data_ext = {{8{sub_ab[31]}}, sub_ab};
    wire signed [39:0] mnsum91_data_ext = {{8{neg_sum_ab[31]}}, neg_sum_ab};
    wire signed [39:0] mul_c91_full =
        (mul_data_ext <<< 7) -
        (mul_data_ext <<< 5) -
        (mul_data_ext <<< 2) -
        mul_data_ext;
    wire signed [39:0] madd91_full =
        (madd91_data_ext <<< 7) -
        (madd91_data_ext <<< 5) -
        (madd91_data_ext <<< 2) -
        madd91_data_ext;
    wire signed [39:0] msub91_full =
        (msub91_data_ext <<< 7) -
        (msub91_data_ext <<< 5) -
        (msub91_data_ext <<< 2) -
        msub91_data_ext;
    wire signed [39:0] mnsum91_full =
        (mnsum91_data_ext <<< 7) -
        (mnsum91_data_ext <<< 5) -
        (mnsum91_data_ext <<< 2) -
        mnsum91_data_ext;

    always @(*) begin
        case (alu_op)
            `ALU_ADD:     y = a + b;
            `ALU_SUB:     y = a - b;
            `ALU_AND:     y = a & b;
            `ALU_OR:      y = a | b;
            `ALU_MOV:     y = b;
            `ALU_MUL_Q7:  y = mul_c91_full >>> 7;
            `ALU_MADD91:  y = madd91_full >>> 7;
            `ALU_MSUB91:  y = msub91_full >>> 7;
            `ALU_MNSUM91: y = mnsum91_full >>> 7;
            default:      y = 32'sd0;
        endcase
    end

    assign zero = (y == 32'sd0);
    assign negative = y[31];
endmodule
