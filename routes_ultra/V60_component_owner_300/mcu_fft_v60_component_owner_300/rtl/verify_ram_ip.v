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

module verify_RAM_component16(
    input  wire clk,
    input  wire [15:0] verify_we_bus,
    input  wire [79:0] verify_addr_bus,
    input  wire [255:0] verify_vector_out_bus,
    input  wire [4:0] debug_addr,
    output wire [15:0] debug_data
);
    reg [15:0] bank0;
    reg [15:0] bank1;
    reg [15:0] bank2;
    reg [15:0] bank3;
    reg [15:0] bank4;
    reg [15:0] bank5;
    reg [15:0] bank6;
    reg [15:0] bank7;
    reg [15:0] bank8;
    reg [15:0] bank9;
    reg [15:0] bank10;
    reg [15:0] bank11;
    reg [15:0] bank12;
    reg [15:0] bank13;
    reg [15:0] bank14;
    reg [15:0] bank15;

    initial begin
        bank0 = 16'd0;
        bank1 = 16'd0;
        bank2 = 16'd0;
        bank3 = 16'd0;
        bank4 = 16'd0;
        bank5 = 16'd0;
        bank6 = 16'd0;
        bank7 = 16'd0;
        bank8 = 16'd0;
        bank9 = 16'd0;
        bank10 = 16'd0;
        bank11 = 16'd0;
        bank12 = 16'd0;
        bank13 = 16'd0;
        bank14 = 16'd0;
        bank15 = 16'd0;
    end

    always @(posedge clk) begin
        if (verify_we_bus[0])
            bank0 <= verify_vector_out_bus[0*16 +: 16];
        if (verify_we_bus[1])
            bank1 <= verify_vector_out_bus[1*16 +: 16];
        if (verify_we_bus[2])
            bank2 <= verify_vector_out_bus[2*16 +: 16];
        if (verify_we_bus[3])
            bank3 <= verify_vector_out_bus[3*16 +: 16];
        if (verify_we_bus[4])
            bank4 <= verify_vector_out_bus[4*16 +: 16];
        if (verify_we_bus[5])
            bank5 <= verify_vector_out_bus[5*16 +: 16];
        if (verify_we_bus[6])
            bank6 <= verify_vector_out_bus[6*16 +: 16];
        if (verify_we_bus[7])
            bank7 <= verify_vector_out_bus[7*16 +: 16];
        if (verify_we_bus[8])
            bank8 <= verify_vector_out_bus[8*16 +: 16];
        if (verify_we_bus[9])
            bank9 <= verify_vector_out_bus[9*16 +: 16];
        if (verify_we_bus[10])
            bank10 <= verify_vector_out_bus[10*16 +: 16];
        if (verify_we_bus[11])
            bank11 <= verify_vector_out_bus[11*16 +: 16];
        if (verify_we_bus[12])
            bank12 <= verify_vector_out_bus[12*16 +: 16];
        if (verify_we_bus[13])
            bank13 <= verify_vector_out_bus[13*16 +: 16];
        if (verify_we_bus[14])
            bank14 <= verify_vector_out_bus[14*16 +: 16];
        if (verify_we_bus[15])
            bank15 <= verify_vector_out_bus[15*16 +: 16];
    end

    assign debug_data =
        (debug_addr[3:0] == 4'd0) ? bank0 :
        (debug_addr[3:0] == 4'd1) ? bank1 :
        (debug_addr[3:0] == 4'd2) ? bank2 :
        (debug_addr[3:0] == 4'd3) ? bank3 :
        (debug_addr[3:0] == 4'd4) ? bank4 :
        (debug_addr[3:0] == 4'd5) ? bank5 :
        (debug_addr[3:0] == 4'd6) ? bank6 :
        (debug_addr[3:0] == 4'd7) ? bank7 :
        (debug_addr[3:0] == 4'd8) ? bank8 :
        (debug_addr[3:0] == 4'd9) ? bank9 :
        (debug_addr[3:0] == 4'd10) ? bank10 :
        (debug_addr[3:0] == 4'd11) ? bank11 :
        (debug_addr[3:0] == 4'd12) ? bank12 :
        (debug_addr[3:0] == 4'd13) ? bank13 :
        (debug_addr[3:0] == 4'd14) ? bank14 :
                                      bank15;
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
