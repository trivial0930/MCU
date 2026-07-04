module board_top(
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
    wire [7:0] test_rom_addr;
    wire [15:0] test_vector_in;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [19:0] cnt_test;
    wire done;
    wire [15:0] verify_debug_data;

    clk_ultra_pll u_clk_ultra_pll (
        .clk_in(CLK_50M),
        .clk_out(clk),
        .locked(pll_locked)
    );

    assign rst = ~KEY1 | ~pll_locked;

    test_ROM #(
        .INIT_FILE("mem/FFT_input.mem")
    ) u_test_ROM (
        .clk(clk),
        .addr(test_rom_addr),
        .test_vector_in(test_vector_in)
    );

    mcu_top u_mcu_top (
        .clk(clk),
        .rst(rst),
        .test_rom_addr(test_rom_addr),
        .test_vector_in(test_vector_in),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .cnt_test(cnt_test),
        .done(done)
    );

    verify_RAM u_verify_RAM (
        .clk(clk),
        .we(verify_we),
        .addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .debug_addr(verify_addr),
        .debug_data(verify_debug_data)
    );

    ila_probe u_ila_probe (
        .clk(clk),
        .test_vector_in(test_vector_in),
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
    assign LED8 = ^verify_debug_data;
endmodule

module clk_ultra_pll(
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
        .CLKFBOUT_MULT(18),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(3),
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
