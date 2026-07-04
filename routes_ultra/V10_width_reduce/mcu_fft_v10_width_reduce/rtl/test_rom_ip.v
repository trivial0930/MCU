module test_ROM #(
    parameter INIT_FILE = "mem/test_vector.mem"
)(
    input  wire clk,
    input  wire [7:0] addr,
    output wire [15:0] test_vector_in
);
    reg [15:0] rom [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 16'd0;
        $readmemh(INIT_FILE, rom);
    end

    assign test_vector_in = rom[addr];
endmodule
