`include "tb_defs.vh"

module tb_mcu_fft8;
    reg clk;
    reg rst;
    wire [7:0] test_rom_addr [0:7];
    wire [15:0] test_vector_in [0:7];
    wire [4:0] verify_addr_i [0:7];
    wire [15:0] verify_vector_out_i [0:7];
    wire [7:0] verify_we_i;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire [15:0] verify_done_mask;
    wire [19:0] cnt_test;
    wire done;

    reg [15:0] test_rom [0:255];
    reg [15:0] verify_ram [0:15];
    reg [8*256:1] test_mem_file;
    reg [8*256:1] out_file;
    reg [8*256:1] verify_trace_file;
    reg [8*256:1] input_trace_file;
    reg [7:0] last_input_addr [0:7];
    integer i;
    integer j;
    integer fd;
    integer verify_fd;
    integer input_fd;
    integer cycles;
    integer write_count;

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_test_mem_read
            assign test_vector_in[gi] = test_rom[test_rom_addr[gi]];
        end
    endgenerate

    mcu_top dut(
        .clk(clk),
        .rst(rst),
        .test_rom_addr0(test_rom_addr[0]),
        .test_rom_addr1(test_rom_addr[1]),
        .test_rom_addr2(test_rom_addr[2]),
        .test_rom_addr3(test_rom_addr[3]),
        .test_rom_addr4(test_rom_addr[4]),
        .test_rom_addr5(test_rom_addr[5]),
        .test_rom_addr6(test_rom_addr[6]),
        .test_rom_addr7(test_rom_addr[7]),
        .test_vector_in0(test_vector_in[0]),
        .test_vector_in1(test_vector_in[1]),
        .test_vector_in2(test_vector_in[2]),
        .test_vector_in3(test_vector_in[3]),
        .test_vector_in4(test_vector_in[4]),
        .test_vector_in5(test_vector_in[5]),
        .test_vector_in6(test_vector_in[6]),
        .test_vector_in7(test_vector_in[7]),
        .verify_addr0(verify_addr_i[0]),
        .verify_addr1(verify_addr_i[1]),
        .verify_addr2(verify_addr_i[2]),
        .verify_addr3(verify_addr_i[3]),
        .verify_addr4(verify_addr_i[4]),
        .verify_addr5(verify_addr_i[5]),
        .verify_addr6(verify_addr_i[6]),
        .verify_addr7(verify_addr_i[7]),
        .verify_vector_out0(verify_vector_out_i[0]),
        .verify_vector_out1(verify_vector_out_i[1]),
        .verify_vector_out2(verify_vector_out_i[2]),
        .verify_vector_out3(verify_vector_out_i[3]),
        .verify_vector_out4(verify_vector_out_i[4]),
        .verify_vector_out5(verify_vector_out_i[5]),
        .verify_vector_out6(verify_vector_out_i[6]),
        .verify_vector_out7(verify_vector_out_i[7]),
        .verify_we0(verify_we_i[0]),
        .verify_we1(verify_we_i[1]),
        .verify_we2(verify_we_i[2]),
        .verify_we3(verify_we_i[3]),
        .verify_we4(verify_we_i[4]),
        .verify_we5(verify_we_i[5]),
        .verify_we6(verify_we_i[6]),
        .verify_we7(verify_we_i[7]),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .verify_done_mask(verify_done_mask),
        .cnt_test(cnt_test),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    task record_verify;
        input [2:0] core_id;
        input [4:0] addr;
        input [15:0] data;
        begin
            verify_ram[addr[3:0]] <= data;
            write_count = write_count + 1;
            if (verify_fd != 0)
                $fdisplay(verify_fd, "%0d,%0d,%04h,Core%0d,%0d", cycles, addr, data, core_id, (verify_done_mask | (16'h0001 << addr[3:0])) == 16'hffff);
`ifdef TRACE_VERIFY
            $display("verify cycle=%0d core=%0d addr=%0d data=%04h", cycles, core_id, addr, data);
`endif
        end
    endtask

    task record_input;
        input [2:0] core_id;
        input [7:0] addr;
        input [15:0] data;
        begin
            if (input_fd != 0)
                $fdisplay(input_fd, "%0d,%0d,%0d,%04h", cycles, core_id, addr, data);
        end
    endtask

    always @(posedge clk) begin
        if (!rst) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (verify_we_i[j])
                    record_verify(j[2:0], verify_addr_i[j], verify_vector_out_i[j]);
                if (test_rom_addr[j] >= 8'd128 && test_rom_addr[j] < 8'd144 && test_rom_addr[j] != last_input_addr[j]) begin
                    record_input(j[2:0], test_rom_addr[j], test_vector_in[j]);
                    last_input_addr[j] <= test_rom_addr[j];
                end
            end
        end
    end

    initial begin
        for (i = 0; i < 256; i = i + 1)
            test_rom[i] = 16'd0;
        for (i = 0; i < 16; i = i + 1)
            verify_ram[i] = 16'd0;

        test_mem_file = "mem/FFT_input.mem";
        out_file = "results/verify_output.txt";
        verify_trace_file = "";
        input_trace_file = "";
        if ($value$plusargs("TEST_MEM=%s", test_mem_file))
            $display("Loading test memory: %0s", test_mem_file);
        else
            $display("Loading test memory: %0s", test_mem_file);
        if ($value$plusargs("OUT_FILE=%s", out_file))
            $display("Writing verify output: %0s", out_file);
        else
            $display("Writing verify output: %0s", out_file);
        if ($value$plusargs("VERIFY_TRACE=%s", verify_trace_file))
            $display("Writing verify trace: %0s", verify_trace_file);
        if ($value$plusargs("INPUT_TRACE=%s", input_trace_file))
            $display("Writing input trace: %0s", input_trace_file);
        $readmemh(test_mem_file, test_rom);

        verify_fd = 0;
        if (verify_trace_file != "")
            verify_fd = $fopen(verify_trace_file, "w");
        if (verify_fd != 0)
            $fdisplay(verify_fd, "cycle,verify_addr,verify_data,writer_core,is_last_write");
        input_fd = 0;
        if (input_trace_file != "")
            input_fd = $fopen(input_trace_file, "w");
        if (input_fd != 0)
            $fdisplay(input_fd, "cycle,core_id,input_addr,input_data");

        rst = 1'b1;
        cycles = 0;
        write_count = 0;
        for (i = 0; i < 8; i = i + 1)
            last_input_addr[i] = 8'hff;
        repeat (5) @(posedge clk);
        rst = 1'b0;

        while (!done && cycles < `TIMEOUT_CYCLES) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (!done) begin
            $display("ERROR: simulation timeout");
            $finish;
        end

        repeat (2) @(posedge clk);
        $display("done cycles=%0d cnt_test=%0d verify_writes=%0d done_mask=%04h", cycles, cnt_test, write_count, verify_done_mask);

        fd = $fopen(out_file, "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fd, "%04h", verify_ram[i]);
        $fclose(fd);
        if (verify_fd != 0)
            $fclose(verify_fd);
        if (input_fd != 0)
            $fclose(input_fd);

        $finish;
    end
endmodule
