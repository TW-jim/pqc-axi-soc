`timescale 1ns / 1ps
module Output_Buffer #(
    parameter COEFF_WIDTH = 23,
    parameter DEPTH       = 256,
    parameter ADDR_WIDTH  = 8
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
    localparam BANK_COUNT      = 4;
    localparam BANK_ADDR_WIDTH = ADDR_WIDTH - 2;
    localparam BANK_DEPTH      = DEPTH / BANK_COUNT;
    reg [COEFF_WIDTH - 1 : 0] bank_0 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_1 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_2 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_3 [0 : BANK_DEPTH - 1];
    wire [BANK_ADDR_WIDTH - 1 : 0] w_row_1, w_row_2, w_row_3, w_row_4;
    assign w_row_1 = W_addr_1[ADDR_WIDTH - 1 : 2];
    assign w_row_2 = W_addr_2[ADDR_WIDTH - 1 : 2];
    assign w_row_3 = W_addr_3[ADDR_WIDTH - 1 : 2];
    assign w_row_4 = W_addr_4[ADDR_WIDTH - 1 : 2];
    always @(posedge ACLK) begin
        if(W_EN_1) bank_0[w_row_1] <= W_data_1;
        if(W_EN_2) bank_1[w_row_2] <= W_data_2;
        if(W_EN_3) bank_2[w_row_3] <= W_data_3;
        if(W_EN_4) bank_3[w_row_4] <= W_data_4;
    end
    wire [1 : 0] r_bank;
    wire [BANK_ADDR_WIDTH - 1 : 0] r_row;
    assign r_bank = R_addr[1 : 0];
    assign r_row = R_addr[ADDR_WIDTH - 1 : 2];
    wire [COEFF_WIDTH - 1 : 0] bank_r_data_0, bank_r_data_1, bank_r_data_2, bank_r_data_3;
    assign bank_r_data_0 = bank_0[r_row];
    assign bank_r_data_1 = bank_1[r_row];
    assign bank_r_data_2 = bank_2[r_row];
    assign bank_r_data_3 = bank_3[r_row];
    assign R_data =
        (r_bank == 2'b00) ? bank_r_data_0 : (r_bank == 2'b01) ? bank_r_data_1 :
        (r_bank == 2'b10) ? bank_r_data_2 : bank_r_data_3;
endmodule