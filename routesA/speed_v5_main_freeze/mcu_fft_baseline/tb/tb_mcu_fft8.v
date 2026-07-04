`include "tb_defs.vh"

module tb_mcu_fft8;
    reg clk;
    reg rst;
    wire [4:0] test_rom_addr;
    wire [15:0] test_vector_in;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [19:0] cnt_test;
    wire done;

    reg [15:0] test_rom [0:15];
    reg [15:0] verify_ram [0:15];
    reg [8*256:1] test_mem_file;
    integer i;
    integer fd;
    integer cycles;

    assign test_vector_in = test_rom[test_rom_addr[3:0]];

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
        for (i = 0; i < 16; i = i + 1) begin
            test_rom[i] = 16'd0;
            verify_ram[i] = 16'd0;
        end

        test_mem_file = "mem/test_vector.mem";
        if ($value$plusargs("TEST_MEM=%s", test_mem_file))
            $display("Loading test memory: %0s", test_mem_file);
        else
            $display("Loading test memory: %0s", test_mem_file);
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

        fd = $fopen("results/verify_output.txt", "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fd, "%04h", verify_ram[i]);
        $fclose(fd);

        $finish;
    end
endmodule
