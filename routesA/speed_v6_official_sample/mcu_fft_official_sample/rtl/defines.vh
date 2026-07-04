`ifndef MCU_FFT_DEFINES_VH
`define MCU_FFT_DEFINES_VH

`define OP_NOP   4'h0
`define OP_ADD   4'h1
`define OP_SUB   4'h2
`define OP_AND   4'h3
`define OP_OR    4'h4
`define OP_MOVI  4'h5
`define OP_MOVR  4'h6
`define OP_LDR   4'h7
`define OP_STR   4'h8
`define OP_B     4'h9
`define OP_BL    4'hA
`define OP_CMP   4'hB
`define OP_BEQ   4'hC
`define OP_BNE   4'hD
`define OP_MUL   4'hE
`define OP_HALT  4'hF

`define ALU_ADD      4'h0
`define ALU_SUB      4'h1
`define ALU_AND      4'h2
`define ALU_OR       4'h3
`define ALU_MOV      4'h4
`define ALU_MUL_Q7   4'h5

`define TEST_BASE    32'h00001000
`define VERIFY_BASE  32'h00002000

`endif
