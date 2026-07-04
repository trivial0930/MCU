module board_top #(
    parameter integer PLL_CLKFBOUT_MULT = 30,
    parameter integer PLL_CLKOUT0_DIVIDE = 5
)(
    input  wire CLK_50M,
    input  wire KEY1,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,
    output wire LED6,
    output wire LED7,
    output wire LED8
);
    wire clk;
    wire rst;
    wire pll_locked;
    wire [7:0] test_rom_addr0;
    wire [7:0] test_rom_addr1;
    wire [7:0] test_rom_addr2;
    wire [7:0] test_rom_addr3;
    wire [15:0] test_vector_in0;
    wire [15:0] test_vector_in1;
    wire [15:0] test_vector_in2;
    wire [15:0] test_vector_in3;
    wire [4:0] verify_addr0;
    wire [4:0] verify_addr1;
    wire [4:0] verify_addr2;
    wire [4:0] verify_addr3;
    wire [15:0] verify_vector_out0;
    wire [15:0] verify_vector_out1;
    wire [15:0] verify_vector_out2;
    wire [15:0] verify_vector_out3;
    wire verify_we0;
    wire verify_we1;
    wire verify_we2;
    wire verify_we3;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [15:0] verify_done_mask;
    wire [19:0] cnt_test;
    wire done;
    wire [15:0] verify_debug_data;

    clk_ultra_pll #(
        .PLL_CLKFBOUT_MULT(PLL_CLKFBOUT_MULT),
        .PLL_CLKOUT0_DIVIDE(PLL_CLKOUT0_DIVIDE)
    ) u_clk_ultra_pll (
        .clk_in(CLK_50M),
        .clk_out(clk),
        .locked(pll_locked)
    );

    assign rst = ~KEY1 | ~pll_locked;

    test_ROM #(.INIT_FILE("mem/FFT_input.mem")) u_test_ROM0 (
        .clk(clk),
        .addr(test_rom_addr0),
        .test_vector_in(test_vector_in0)
    );

    test_ROM #(.INIT_FILE("mem/FFT_input.mem")) u_test_ROM1 (
        .clk(clk),
        .addr(test_rom_addr1),
        .test_vector_in(test_vector_in1)
    );

    test_ROM #(.INIT_FILE("mem/FFT_input.mem")) u_test_ROM2 (
        .clk(clk),
        .addr(test_rom_addr2),
        .test_vector_in(test_vector_in2)
    );

    test_ROM #(.INIT_FILE("mem/FFT_input.mem")) u_test_ROM3 (
        .clk(clk),
        .addr(test_rom_addr3),
        .test_vector_in(test_vector_in3)
    );

    mcu_top u_mcu_top (
        .clk(clk),
        .rst(rst),
        .test_rom_addr0(test_rom_addr0),
        .test_rom_addr1(test_rom_addr1),
        .test_rom_addr2(test_rom_addr2),
        .test_rom_addr3(test_rom_addr3),
        .test_vector_in0(test_vector_in0),
        .test_vector_in1(test_vector_in1),
        .test_vector_in2(test_vector_in2),
        .test_vector_in3(test_vector_in3),
        .verify_addr0(verify_addr0),
        .verify_addr1(verify_addr1),
        .verify_addr2(verify_addr2),
        .verify_addr3(verify_addr3),
        .verify_vector_out0(verify_vector_out0),
        .verify_vector_out1(verify_vector_out1),
        .verify_vector_out2(verify_vector_out2),
        .verify_vector_out3(verify_vector_out3),
        .verify_we0(verify_we0),
        .verify_we1(verify_we1),
        .verify_we2(verify_we2),
        .verify_we3(verify_we3),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .verify_done_mask(verify_done_mask),
        .cnt_test(cnt_test),
        .done(done)
    );

    verify_RAM_quad u_verify_RAM_quad (
        .clk(clk),
        .we0(verify_we0),
        .addr0(verify_addr0),
        .data0(verify_vector_out0),
        .we1(verify_we1),
        .addr1(verify_addr1),
        .data1(verify_vector_out1),
        .we2(verify_we2),
        .addr2(verify_addr2),
        .data2(verify_vector_out2),
        .we3(verify_we3),
        .addr3(verify_addr3),
        .data3(verify_vector_out3),
        .debug_addr(verify_addr),
        .debug_data(verify_debug_data)
    );

    ila_probe u_ila_probe (
        .clk(clk),
        .test_vector_in(test_vector_in0),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .verify_addr(verify_addr),
        .cnt_test(cnt_test),
        .done(done)
    );

    assign LED1 = done;
    assign LED2 = verify_we;
    assign LED3 = cnt_test[0];
    assign LED4 = cnt_test[4];
    assign LED5 = cnt_test[8];
    assign LED6 = cnt_test[12];
    assign LED7 = cnt_test[16];
    assign LED8 = ^(verify_debug_data ^ verify_done_mask);
endmodule

module clk_ultra_pll #(
    parameter integer PLL_CLKFBOUT_MULT = 30,
    parameter integer PLL_CLKOUT0_DIVIDE = 5
)(
    input wire clk_in,
    output wire clk_out,
    output wire locked
);
    wire clkfb;
    wire clkfb_buf;
    wire clkout_raw;

    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(20.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT(PLL_CLKFBOUT_MULT),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(PLL_CLKOUT0_DIVIDE),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .STARTUP_WAIT("FALSE")
    ) u_plle2_base (
        .CLKIN1(clk_in),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),
        .CLKOUT0(clkout_raw),
        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(1'b0)
    );

    BUFG u_clkfb_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_clkout_buf (
        .I(clkout_raw),
        .O(clk_out)
    );
endmodule
