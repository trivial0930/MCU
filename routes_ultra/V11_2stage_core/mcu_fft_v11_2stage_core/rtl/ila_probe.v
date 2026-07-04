module ila_probe(
    input wire clk,
    input wire [15:0] test_vector_in,
    input wire [15:0] verify_vector_out,
    input wire verify_we,
    input wire [4:0] verify_addr,
    input wire [19:0] cnt_test,
    input wire done
);
`ifdef ENABLE_ILA
    ila_0 u_ila_0 (
        .clk(clk),
        .probe0(test_vector_in),
        .probe1(verify_vector_out),
        .probe2(verify_we),
        .probe3(verify_addr),
        .probe4(cnt_test),
        .probe5(done)
    );
`endif
endmodule
