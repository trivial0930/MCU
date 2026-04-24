`timescale 1ns / 1ps

module clk_wiz_0 (
    input  wire clk_in1,
    output wire clk_out1
);

    // 这里只是为了 Mac 上语法检查通过
    // 真正上板时，Windows Vivado 中会生成真实 Clocking Wizard IP
    assign clk_out1 = clk_in1;

endmodule