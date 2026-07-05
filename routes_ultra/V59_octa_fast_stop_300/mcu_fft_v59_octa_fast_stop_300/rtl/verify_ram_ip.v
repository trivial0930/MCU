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

module verify_RAM_quad(
    input  wire clk,
    input  wire we0,
    input  wire [4:0] addr0,
    input  wire [15:0] data0,
    input  wire we1,
    input  wire [4:0] addr1,
    input  wire [15:0] data1,
    input  wire we2,
    input  wire [4:0] addr2,
    input  wire [15:0] data2,
    input  wire we3,
    input  wire [4:0] addr3,
    input  wire [15:0] data3,
    input  wire [4:0] debug_addr,
    output wire [15:0] debug_data
);
    reg [15:0] ram_core0 [0:3];
    reg [15:0] ram_core1 [0:3];
    reg [15:0] ram_core2 [0:3];
    reg [15:0] ram_core3 [0:3];
    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            ram_core0[i] = 16'd0;
            ram_core1[i] = 16'd0;
            ram_core2[i] = 16'd0;
            ram_core3[i] = 16'd0;
        end
    end

    always @(posedge clk) begin
        if (we0)
            ram_core0[addr0[3:2]] <= data0;
        if (we1)
            ram_core1[addr1[3:2]] <= data1;
        if (we2)
            ram_core2[addr2[3:2]] <= data2;
        if (we3)
            ram_core3[addr3[3:2]] <= data3;
    end

    assign debug_data =
        (debug_addr[1:0] == 2'd0) ? ram_core0[debug_addr[3:2]] :
        (debug_addr[1:0] == 2'd1) ? ram_core1[debug_addr[3:2]] :
        (debug_addr[1:0] == 2'd2) ? ram_core2[debug_addr[3:2]] :
                                    ram_core3[debug_addr[3:2]];
endmodule

module verify_RAM_oct(
    input  wire clk,
    input  wire we0,
    input  wire [4:0] addr0,
    input  wire [15:0] data0,
    input  wire we1,
    input  wire [4:0] addr1,
    input  wire [15:0] data1,
    input  wire we2,
    input  wire [4:0] addr2,
    input  wire [15:0] data2,
    input  wire we3,
    input  wire [4:0] addr3,
    input  wire [15:0] data3,
    input  wire we4,
    input  wire [4:0] addr4,
    input  wire [15:0] data4,
    input  wire we5,
    input  wire [4:0] addr5,
    input  wire [15:0] data5,
    input  wire we6,
    input  wire [4:0] addr6,
    input  wire [15:0] data6,
    input  wire we7,
    input  wire [4:0] addr7,
    input  wire [15:0] data7,
    input  wire [4:0] debug_addr,
    output wire [15:0] debug_data
);
    reg [15:0] ram_core0 [0:1];
    reg [15:0] ram_core1 [0:1];
    reg [15:0] ram_core2 [0:1];
    reg [15:0] ram_core3 [0:1];
    reg [15:0] ram_core4 [0:1];
    reg [15:0] ram_core5 [0:1];
    reg [15:0] ram_core6 [0:1];
    reg [15:0] ram_core7 [0:1];
    integer i;

    initial begin
        for (i = 0; i < 2; i = i + 1) begin
            ram_core0[i] = 16'd0;
            ram_core1[i] = 16'd0;
            ram_core2[i] = 16'd0;
            ram_core3[i] = 16'd0;
            ram_core4[i] = 16'd0;
            ram_core5[i] = 16'd0;
            ram_core6[i] = 16'd0;
            ram_core7[i] = 16'd0;
        end
    end

    always @(posedge clk) begin
        if (we0)
            ram_core0[addr0[3]] <= data0;
        if (we1)
            ram_core1[addr1[3]] <= data1;
        if (we2)
            ram_core2[addr2[3]] <= data2;
        if (we3)
            ram_core3[addr3[3]] <= data3;
        if (we4)
            ram_core4[addr4[3]] <= data4;
        if (we5)
            ram_core5[addr5[3]] <= data5;
        if (we6)
            ram_core6[addr6[3]] <= data6;
        if (we7)
            ram_core7[addr7[3]] <= data7;
    end

    assign debug_data =
        (debug_addr[2:0] == 3'd0) ? ram_core0[debug_addr[3]] :
        (debug_addr[2:0] == 3'd1) ? ram_core1[debug_addr[3]] :
        (debug_addr[2:0] == 3'd2) ? ram_core2[debug_addr[3]] :
        (debug_addr[2:0] == 3'd3) ? ram_core3[debug_addr[3]] :
        (debug_addr[2:0] == 3'd4) ? ram_core4[debug_addr[3]] :
        (debug_addr[2:0] == 3'd5) ? ram_core5[debug_addr[3]] :
        (debug_addr[2:0] == 3'd6) ? ram_core6[debug_addr[3]] :
                                    ram_core7[debug_addr[3]];
endmodule
