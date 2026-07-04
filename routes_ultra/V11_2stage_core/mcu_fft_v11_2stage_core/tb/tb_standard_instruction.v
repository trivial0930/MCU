`include "tb_defs.vh"

module tb_standard_instruction;
    reg clk;
    reg rst;
    wire [7:0] test_rom_addr;
    wire [15:0] test_vector_in;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [19:0] cnt_test;
    wire done;

    reg [15:0] test_rom [0:255];
    reg [15:0] verify_ram [0:15];
    integer i;
    integer cycles;

    assign test_vector_in = test_rom[test_rom_addr];

    mcu_top dut(
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

    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    always @(posedge clk) begin
        if (verify_we)
            verify_ram[verify_addr[3:0]] <= verify_vector_out;
    end

    initial begin
        for (i = 0; i < 256; i = i + 1)
            test_rom[i] = 16'd0;

        for (i = 0; i < 16; i = i + 1)
            verify_ram[i] = 16'd0;

        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;

        cycles = 0;
        while (!done && cycles < `TIMEOUT_CYCLES) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (!done) begin
            $display("ERROR: standard instruction timeout");
            $finish;
        end

        repeat (2) @(posedge clk);
        $display("STD verify[0]=%0d verify[1]=%0d verify[2]=%0d verify[3]=%0d verify[15]=%0d",
                 $signed(verify_ram[0]), $signed(verify_ram[1]), $signed(verify_ram[2]),
                 $signed(verify_ram[3]), $signed(verify_ram[15]));
        $finish;
    end
endmodule
