`include "tb_defs.vh"

module tb_standard_instruction;
    reg clk;
    reg rst;
    wire [15:0] instr_addr;
    wire [31:0] instr;
    wire [15:0] dmem_addr;
    wire [15:0] dmem_wdata;
    wire dmem_we;
    wire [15:0] dmem_rdata;
    wire [7:0] test_rom_addr;
    wire [15:0] test_vector_in;
    wire [4:0] verify_addr;
    wire [15:0] verify_vector_out;
    wire verify_we;
    wire first_test_rom_read;
    wire last_verify_ram_write;
    wire done;

    reg [15:0] test_rom [0:255];
    reg [15:0] verify_ram [0:15];
    integer i;
    integer cycles;
    integer errors;

    assign test_vector_in = test_rom[test_rom_addr];

    instr_rom #(.INIT_FILE("instr_standard.mem")) u_instr_rom (
        .addr(instr_addr),
        .instr(instr)
    );

    data_ram u_data_ram (
        .clk(clk),
        .we(dmem_we),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata)
    );

    mcu_core dut (
        .clk(clk),
        .rst(rst),
        .instr_addr(instr_addr),
        .instr(instr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata),
        .test_rom_addr(test_rom_addr),
        .test_vector_in(test_vector_in),
        .verify_addr(verify_addr),
        .verify_vector_out(verify_vector_out),
        .verify_we(verify_we),
        .first_test_rom_read(first_test_rom_read),
        .last_verify_ram_write(last_verify_ram_write),
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

    task expect16;
        input [3:0] addr;
        input [15:0] expected;
        begin
            if (verify_ram[addr] !== expected) begin
                $display("ERROR: verify[%0d] expected %04h got %04h", addr, expected, verify_ram[addr]);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        for (i = 0; i < 256; i = i + 1)
            test_rom[i] = 16'd0;
        for (i = 0; i < 16; i = i + 1)
            verify_ram[i] = 16'd0;

        rst = 1'b1;
        errors = 0;
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
        expect16(4'd0, 16'h4002);
        expect16(4'd1, 16'h3ffe);
        expect16(4'd2, 16'h0000);
        expect16(4'd3, 16'h4002);
        expect16(4'd4, 16'h4002);
        expect16(4'd5, 16'h4002);
        expect16(4'd15, 16'h0100);

        if (errors == 0)
            $display("STANDARD_INSTRUCTION_TEST PASS cycles=%0d", cycles);
        else
            $display("STANDARD_INSTRUCTION_TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
