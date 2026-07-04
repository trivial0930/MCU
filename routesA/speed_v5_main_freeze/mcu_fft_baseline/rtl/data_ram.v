module data_ram(
    input  wire clk,
    input  wire we,
    input  wire [15:0] addr,
    input  wire [15:0] wdata,
    output wire [15:0] rdata
);
    reg [15:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'd0;
    end

    assign rdata = mem[addr[7:0]];

    always @(posedge clk) begin
        if (we)
            mem[addr[7:0]] <= wdata;
    end
endmodule
