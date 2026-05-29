module reg_file(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] raddr1,
    input  wire [3:0] raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2,
    input  wire we,
    input  wire [3:0] waddr,
    input  wire [31:0] wdata
);
    reg [31:0] regs [0:15];
    integer i;

    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end
endmodule
