module verify_RAM(
    input  wire clk,
    input  wire we,
    input  wire [4:0] addr,
    input  wire [15:0] verify_vector_out,
    input  wire [4:0] debug_addr,
    output wire [15:0] debug_data
);
    reg [15:0] ram [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            ram[i] = 16'd0;
    end

    always @(posedge clk) begin
        if (we)
            ram[addr[3:0]] <= verify_vector_out;
    end

    assign debug_data = ram[debug_addr[3:0]];
endmodule
