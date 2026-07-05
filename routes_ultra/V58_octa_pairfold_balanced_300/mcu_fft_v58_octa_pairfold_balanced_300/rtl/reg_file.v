module reg_file #(
    parameter DATA_W = 32
)(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] raddr1,
    input  wire [3:0] raddr2,
    output wire signed [DATA_W-1:0] rdata1,
    output wire signed [DATA_W-1:0] rdata2,
    input  wire we,
    input  wire [3:0] waddr,
    input  wire signed [DATA_W-1:0] wdata
);
    reg [DATA_W-1:0] regs [0:15];
    integer i;

    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= {DATA_W{1'b0}};
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end
endmodule
