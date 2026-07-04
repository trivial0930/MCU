`include "tb_defs.vh"

module tb_mcu_fft8;
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
    reg [8*256:1] test_mem_file;
    reg [8*256:1] out_file;
    integer i;
    integer fd;
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
        if (verify_we) begin
            verify_ram[verify_addr[3:0]] <= verify_vector_out;
`ifdef TRACE_VERIFY
            $display("verify cycle=%0d addr=%0d data=%04h", cycles, verify_addr, verify_vector_out);
`endif
        end
    end

    initial begin
        for (i = 0; i < 256; i = i + 1)
            test_rom[i] = 16'd0;

        for (i = 0; i < 16; i = i + 1)
            verify_ram[i] = 16'd0;

        test_mem_file = "mem/FFT_input.mem";
        out_file = "results/verify_output.txt";
        if ($value$plusargs("TEST_MEM=%s", test_mem_file))
            $display("Loading test memory: %0s", test_mem_file);
        else
            $display("Loading test memory: %0s", test_mem_file);
        if ($value$plusargs("OUT_FILE=%s", out_file))
            $display("Writing verify output: %0s", out_file);
        else
            $display("Writing verify output: %0s", out_file);
        $readmemh(test_mem_file, test_rom);

        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;

        cycles = 0;
        while (!done && cycles < `TIMEOUT_CYCLES) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (!done) begin
            $display("ERROR: simulation timeout");
            $finish;
        end

        repeat (2) @(posedge clk);
        $display("done cycles=%0d cnt_test=%0d", cycles, cnt_test);

        fd = $fopen(out_file, "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fd, "%04h", verify_ram[i]);
        $fclose(fd);

        $finish;
    end
endmodule
