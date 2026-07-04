module cnt_test_unit(
    input  wire clk,
    input  wire rst,
    input  wire start_pulse,
    input  wire stop_pulse,
    output reg  [19:0] cnt_test
);
    reg running;
    reg stopped;

    always @(posedge clk) begin
        if (rst) begin
            cnt_test <= 20'd0;
            running <= 1'b0;
            stopped <= 1'b0;
        end else begin
            if (start_pulse && !running && !stopped) begin
                running <= 1'b1;
                cnt_test <= cnt_test + 20'd1;
            end else if (running && !stopped) begin
                cnt_test <= cnt_test + 20'd1;
            end

            if (stop_pulse && running) begin
                running <= 1'b0;
                stopped <= 1'b1;
            end
        end
    end
endmodule
