`timescale 1ns / 1ps
module Input_Buffer #(
    parameter COEFF_WIDTH = 23,
    parameter DEPTH = 256,
    parameter ADDR_WITDH = 8
)(
    input ACLK,
    input W_EN,
    input [ADDR_WITDH - 1 : 0] W_addr,
    input [COEFF_WIDTH - 1 : 0] W_data,
    input [ADDR_WITDH - 1 : 0] R_addr_1,
    input [ADDR_WITDH - 1 : 0] R_addr_2,
    input [ADDR_WITDH - 1 : 0] R_addr_3,
    input [ADDR_WITDH - 1 : 0] R_addr_4,
    output [COEFF_WIDTH - 1 : 0] R_data_1,
    output [COEFF_WIDTH - 1 : 0] R_data_2,
    output [COEFF_WIDTH - 1 : 0] R_data_3,
    output [COEFF_WIDTH - 1 : 0] R_data_4
);
    reg [COEFF_WIDTH - 1 : 0] mem [0 : DEPTH - 1];
    always @(posedge ACLK) begin
        if(W_EN) mem[W_addr] <= W_data;
    end
    assign R_data_1 = mem[R_addr_1];
    assign R_data_2 = mem[R_addr_2];
    assign R_data_3 = mem[R_addr_3];
    assign R_data_4 = mem[R_addr_4];
endmodule
