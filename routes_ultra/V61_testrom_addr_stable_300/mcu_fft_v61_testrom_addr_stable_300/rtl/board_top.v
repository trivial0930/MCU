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
    wire [127:0] test_rom_addr_bus;
    wire [255:0] test_vector_in_bus;
    wire [79:0] verify_addr_bus;
    wire [255:0] verify_vector_out_bus;
    wire [15:0] verify_we_bus;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [15:0] verify_done_mask;
    wire [19:0] cnt_test;
    wire done;
    wire [15:0] verify_debug_data;
`ifdef ENABLE_ILA
    wire [15:0] verify_done_mask_next_dbg;
    wire fast_stop_pulse_dbg;
`endif

    clk_ultra_pll #(
        .PLL_CLKFBOUT_MULT(PLL_CLKFBOUT_MULT),
        .PLL_CLKOUT0_DIVIDE(PLL_CLKOUT0_DIVIDE)
    ) u_clk_ultra_pll (
        .clk_in(CLK_50M),
        .clk_out(clk),
        .locked(pll_locked)
    );

`ifdef ENABLE_ILA
    reg [33:0] ila_reset_delay_q = 34'd0;
    reg ila_reset_hold_q = 1'b1;

    always @(posedge clk or negedge pll_locked) begin
        if (!pll_locked) begin
            ila_reset_delay_q <= 34'd0;
            ila_reset_hold_q <= 1'b1;
        end else if (!ila_reset_delay_q[33]) begin
            ila_reset_delay_q <= ila_reset_delay_q + 34'd1;
            ila_reset_hold_q <= 1'b1;
        end else begin
            ila_reset_hold_q <= 1'b0;
        end
    end

    assign rst = ~KEY1 | ~pll_locked | ila_reset_hold_q;
`else
    assign rst = ~KEY1 | ~pll_locked;
`endif

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_test_rom
            test_ROM #(.INIT_FILE("mem/FFT_input.mem")) u_test_ROM (
                .clk(clk),
                .addr(test_rom_addr_bus[gi*8 +: 8]),
                .test_vector_in(test_vector_in_bus[gi*16 +: 16])
            );
        end
    endgenerate

    mcu_top u_mcu_top (
        .clk(clk),
        .rst(rst),
        .test_rom_addr_bus(test_rom_addr_bus),
        .test_vector_in_bus(test_vector_in_bus),
        .verify_addr_bus(verify_addr_bus),
        .verify_vector_out_bus(verify_vector_out_bus),
        .verify_we_bus(verify_we_bus),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .verify_done_mask(verify_done_mask),
        .cnt_test(cnt_test),
        .done(done)
`ifdef ENABLE_ILA
        ,
        .verify_done_mask_next_dbg(verify_done_mask_next_dbg),
        .fast_stop_pulse_dbg(fast_stop_pulse_dbg)
`endif
    );

    verify_RAM_component16 u_verify_RAM_component16 (
        .clk(clk),
        .verify_we_bus(verify_we_bus),
        .verify_addr_bus(verify_addr_bus),
        .verify_vector_out_bus(verify_vector_out_bus),
        .debug_addr(verify_addr),
        .debug_data(verify_debug_data)
    );

    ila_probe u_ila_probe (
        .clk(clk),
        .test_vector_in(test_vector_in_bus[15:0]),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .verify_addr(verify_addr),
        .cnt_test(cnt_test),
        .done(done)
`ifdef ENABLE_ILA
        ,
        .verify_vector_out_all(verify_vector_out_bus),
        .verify_we_all(verify_we_bus),
        .verify_addr_all(verify_addr_bus),
        .verify_done_mask(verify_done_mask),
        .verify_done_mask_next(verify_done_mask_next_dbg),
        .fast_stop_pulse_dbg(fast_stop_pulse_dbg)
`endif
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
