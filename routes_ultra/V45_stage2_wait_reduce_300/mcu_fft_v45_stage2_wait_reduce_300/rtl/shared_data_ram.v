module shared_data_ram(
    input  wire clk,
    input  wire we0,
    input  wire [15:0] addr0,
    input  wire [15:0] wdata0,
    output wire [15:0] rdata0,
    input  wire we1,
    input  wire [15:0] addr1,
    input  wire [15:0] wdata1,
    output wire [15:0] rdata1
);
    reg [15:0] mem0 [0:31];
    reg [15:0] mem1 [0:31];
    integer i;

    wire write_any = we0 | we1;
    wire [4:0] write_addr = we0 ? addr0[4:0] : addr1[4:0];
    wire [15:0] write_data = we0 ? wdata0 : wdata1;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            mem0[i] = 16'd0;
            mem1[i] = 16'd0;
        end
    end

    assign rdata0 = mem0[addr0[4:0]];
    assign rdata1 = mem1[addr1[4:0]];

    always @(posedge clk) begin
        if (write_any) begin
            mem0[write_addr] <= write_data;
            mem1[write_addr] <= write_data;
        end
    end
endmodule
