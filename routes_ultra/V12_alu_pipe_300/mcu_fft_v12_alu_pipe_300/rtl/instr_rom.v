module instr_rom #(
    parameter INIT_FILE = "mem/instr_fft8.mem"
)(
    input  wire [15:0] addr,
    output wire [31:0] instr
);
    reg [31:0] rom [0:1023];
    reg [8*256:1] mem_file;
    integer i;
    integer fd;
    integer scan_ok;

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            rom[i] = 32'h00000000;

        mem_file = INIT_FILE;
        if ($value$plusargs("INSTR_MEM=%s", mem_file))
            $display("Loading instruction memory: %0s", mem_file);
        else
            $display("Loading instruction memory: %0s", mem_file);

`ifdef SYNTHESIS
        $readmemh(INIT_FILE, rom);
`else
        fd = $fopen(mem_file, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open instruction memory %0s", mem_file);
            $finish;
        end
        i = 0;
        while (!$feof(fd) && i < 1024) begin
            scan_ok = $fscanf(fd, "%h\n", rom[i]);
            if (scan_ok == 1)
                i = i + 1;
        end
        $fclose(fd);
`endif
    end

    assign instr = rom[addr[9:0]];
endmodule
