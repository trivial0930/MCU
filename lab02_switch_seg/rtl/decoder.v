`timescale 1ns / 1ps

module decoder (
    input  wire        clk,           // 10MHz clock from Clocking Wizard
    input  wire        rst,           // active-high reset
    input  wire [3:0]  switch_input,  // CODE1-CODE4

    output reg  [3:0]  seg_sel,       // COM1-COM4 digit select
    output reg  [7:0]  seg_output     // {A,B,C,D,E,F,G,DP}
);

    // 10MHz / 5000 = 2KHz
    // 两个数码管轮流显示，所以每个数码管刷新约 1KHz
    reg [12:0] refresh_cnt;
    reg        scan_digit;

    reg [3:0] tens;
    reg [3:0] ones;
    reg [3:0] current_digit;

    wire [4:0] value;
    assign value = {1'b0, switch_input};  // 0-15

    // 把 0-15 转成十位和个位
    always @(*) begin
        tens = value / 10;
        ones = value % 10;
    end

    // 动态扫描计数器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_cnt <= 13'd0;
            scan_digit  <= 1'b0;
        end else begin
            if (refresh_cnt == 13'd4999) begin
                refresh_cnt <= 13'd0;
                scan_digit  <= ~scan_digit;
            end else begin
                refresh_cnt <= refresh_cnt + 13'd1;
            end
        end
    end

    // 位选控制
    // 默认假设 COM 低电平有效
    always @(*) begin
        case (scan_digit)
            1'b0: begin
                seg_sel       = 4'b1110;   // 选择第 1 个数码管，显示个位
                current_digit = ones;
            end

            1'b1: begin
                seg_sel       = 4'b1101;   // 选择第 2 个数码管，显示十位
                current_digit = tens;
            end

            default: begin
                seg_sel       = 4'b1111;
                current_digit = 4'd0;
            end
        endcase
    end

    // 段选译码
    // 默认假设段码低电平有效
    // seg_output[7:0] = {A, B, C, D, E, F, G, DP}
    always @(*) begin
        case (current_digit)
            4'd0: seg_output = 8'b00000011; // 0
            4'd1: seg_output = 8'b10011111; // 1
            4'd2: seg_output = 8'b00100101; // 2
            4'd3: seg_output = 8'b00001101; // 3
            4'd4: seg_output = 8'b10011001; // 4
            4'd5: seg_output = 8'b01001001; // 5
            4'd6: seg_output = 8'b01000001; // 6
            4'd7: seg_output = 8'b00011111; // 7
            4'd8: seg_output = 8'b00000001; // 8
            4'd9: seg_output = 8'b00001001; // 9
            default: seg_output = 8'b11111111; // blank
        endcase
    end

endmodule