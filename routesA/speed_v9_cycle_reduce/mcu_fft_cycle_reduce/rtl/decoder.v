module decoder(
    input  wire [31:0] instr,
    output wire [3:0] opcode,
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,
    output wire [15:0] imm16,
    output wire [31:0] imm32
);
    assign opcode = instr[31:28];
    assign rd     = instr[27:24];
    assign rs1    = instr[23:20];
    assign rs2    = instr[19:16];
    assign imm16  = instr[15:0];
    assign imm32  = {{16{imm16[15]}}, imm16};
endmodule
