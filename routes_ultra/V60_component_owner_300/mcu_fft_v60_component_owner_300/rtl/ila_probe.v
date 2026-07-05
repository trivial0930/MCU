module ila_probe(
    input wire clk,
    input wire [15:0] test_vector_in,
    input wire [15:0] verify_vector_out,
    input wire verify_we,
    input wire [4:0] verify_addr,
    input wire [19:0] cnt_test,
    input wire done
`ifdef ENABLE_ILA
    ,
    input wire [255:0] verify_vector_out_all,
    input wire [15:0] verify_we_all,
    input wire [79:0] verify_addr_all,
    input wire [15:0] verify_done_mask,
    input wire [15:0] verify_done_mask_next,
    input wire fast_stop_pulse_dbg
`endif
);
`ifdef ENABLE_ILA
    ila_0 u_ila_0 (
        .clk(clk),
        .probe0(test_vector_in),
        .probe1(verify_vector_out_all),
        .probe2(verify_we_all),
        .probe3(verify_addr_all),
        .probe4(cnt_test),
        .probe5(done),
        .probe6(verify_done_mask),
        .probe7(verify_done_mask_next),
        .probe8(fast_stop_pulse_dbg)
    );
`endif
endmodule
