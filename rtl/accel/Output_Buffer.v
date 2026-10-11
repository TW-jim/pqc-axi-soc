`timescale 1ns / 1ps
module Output_Buffer #(
    COEFF_WIDTH = 23,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8
)(
    input ACLK,
    input W_EN_1,
    input W_EN_2,
    input W_EN_3,
    input W_EN_4,
    input [ADDR_WIDTH - 1 : 0] W_addr_1,
    input [ADDR_WIDTH - 1 : 0] W_addr_2,
    input [ADDR_WIDTH - 1 : 0] W_addr_3,
    input [ADDR_WIDTH - 1 : 0] W_addr_4,
    input [COEFF_WIDTH - 1 : 0] W_data_1,
    input [COEFF_WIDTH - 1 : 0] W_data_2,
    input [COEFF_WIDTH - 1 : 0] W_data_3,
    input [COEFF_WIDTH - 1 : 0] W_data_4,
    input [ADDR_WIDTH - 1 : 0] R_addr,
    output [COEFF_WIDTH - 1 : 0] R_data
);
    reg [COEFF_WIDTH - 1 : 0] mem [0 : DEPTH - 1];
    assign R_data = mem[R_addr];
    always @(posedge ACLK) begin
        if(W_EN_1) mem[W_addr_1] <= W_data_1;
        if(W_EN_2) mem[W_addr_2] <= W_data_2;
        if(W_EN_3) mem[W_addr_3] <= W_data_3;
        if(W_EN_4) mem[W_addr_4] <= W_data_4;
    end
endmodule
