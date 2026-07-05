module shared_data_ram(
    input  wire clk,
    input  wire we0,
    input  wire [15:0] addr0,
    input  wire [15:0] wdata0,
    output wire [15:0] rdata0,
    input  wire we1,
    input  wire [15:0] addr1,
    input  wire [15:0] wdata1,
    output wire [15:0] rdata1,
    input  wire we2,
    input  wire [15:0] addr2,
    input  wire [15:0] wdata2,
    output wire [15:0] rdata2,
    input  wire we3,
    input  wire [15:0] addr3,
    input  wire [15:0] wdata3,
    output wire [15:0] rdata3
);
    reg [15:0] mem [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            mem[i] = 16'd0;
    end

    assign rdata0 = mem[addr0[4:0]];
    assign rdata1 = mem[addr1[4:0]];
    assign rdata2 = mem[addr2[4:0]];
    assign rdata3 = mem[addr3[4:0]];

    always @(posedge clk) begin
        if (we0)
            mem[addr0[4:0]] <= wdata0;
        if (we1)
            mem[addr1[4:0]] <= wdata1;
        if (we2)
            mem[addr2[4:0]] <= wdata2;
        if (we3)
            mem[addr3[4:0]] <= wdata3;
    end
endmodule
