`timescale 1ns / 1ps
module Input_Buffer #(
    parameter COEFF_WIDTH = 23,
    parameter DEPTH       = 256,
    parameter ADDR_WIDTH  = 8
)(
    input ACLK,
    input W_EN,
    input [ADDR_WIDTH - 1 : 0] W_addr,
    input [COEFF_WIDTH - 1 : 0] W_data,
    input [ADDR_WIDTH - 1 : 0] R_addr_1,
    input [ADDR_WIDTH - 1 : 0] R_addr_2,
    input [ADDR_WIDTH - 1 : 0] R_addr_3,
    input [ADDR_WIDTH - 1 : 0] R_addr_4,
    output [COEFF_WIDTH - 1 : 0] R_data_1,
    output [COEFF_WIDTH - 1 : 0] R_data_2,
    output [COEFF_WIDTH - 1 : 0] R_data_3,
    output [COEFF_WIDTH - 1 : 0] R_data_4
);
    localparam BANK_COUNT = 4;
    localparam BANK_ADDR_WIDTH = ADDR_WIDTH - 2;
    localparam BANK_DEPTH = DEPTH / BANK_COUNT;
    reg [COEFF_WIDTH - 1 : 0] bank_0 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_1 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_2 [0 : BANK_DEPTH - 1];
    reg [COEFF_WIDTH - 1 : 0] bank_3 [0 : BANK_DEPTH - 1];
    function [1 : 0] Get_Bank;
        input [ADDR_WIDTH - 1 : 0] addr;
        begin
            Get_Bank = addr[ADDR_WIDTH - 1 : ADDR_WIDTH - 2] ^ addr[1 : 0];
        end
    endfunction
    function [BANK_ADDR_WIDTH - 1 : 0] Get_Row;
        input [ADDR_WIDTH - 1 : 0] addr;
        begin
            Get_Row = addr[BANK_ADDR_WIDTH - 1 : 0];
        end
    endfunction
    wire [1 : 0] w_bank;
    wire [BANK_ADDR_WIDTH - 1 : 0] w_row;
    assign w_bank = Get_Bank(W_addr);
    assign w_row  = Get_Row(W_addr);
    always @(posedge ACLK) begin
        if(W_EN) begin
            case(w_bank)
                2'b00: bank_0[w_row] <= W_data;
                2'b01: bank_1[w_row] <= W_data;
                2'b10: bank_2[w_row] <= W_data;
                2'b11: bank_3[w_row] <= W_data;
                default: ;
            endcase
        end
    end
    wire [1 : 0] r_bank_1, r_bank_2, r_bank_3, r_bank_4;
    wire [BANK_ADDR_WIDTH - 1 : 0] r_row_1, r_row_2, r_row_3, r_row_4;
    assign r_bank_1 = Get_Bank(R_addr_1);
    assign r_bank_2 = Get_Bank(R_addr_2);
    assign r_bank_3 = Get_Bank(R_addr_3);
    assign r_bank_4 = Get_Bank(R_addr_4);
    assign r_row_1 = Get_Row(R_addr_1);
    assign r_row_2 = Get_Row(R_addr_2);
    assign r_row_3 = Get_Row(R_addr_3);
    assign r_row_4 = Get_Row(R_addr_4);
    wire [3 : 0] bank_req_0, bank_req_1, bank_req_2, bank_req_3;
    assign bank_req_0 = {
        (r_bank_4 == 2'b00),
        (r_bank_3 == 2'b00),
        (r_bank_2 == 2'b00),
        (r_bank_1 == 2'b00)
    };
    assign bank_req_1 = {
        (r_bank_4 == 2'b01),
        (r_bank_3 == 2'b01),
        (r_bank_2 == 2'b01),
        (r_bank_1 == 2'b01)
    };
    assign bank_req_2 = {
        (r_bank_4 == 2'b10),
        (r_bank_3 == 2'b10),
        (r_bank_2 == 2'b10),
        (r_bank_1 == 2'b10)
    };
    assign bank_req_3 = {
        (r_bank_4 == 2'b11),
        (r_bank_3 == 2'b11),
        (r_bank_2 == 2'b11),
        (r_bank_1 == 2'b11)
    };
    reg [BANK_ADDR_WIDTH - 1 : 0] bank_r_addr_0, bank_r_addr_1, bank_r_addr_2, bank_r_addr_3;
    always @(*) begin
        bank_r_addr_0 = {BANK_ADDR_WIDTH{1'b0}};
        case(bank_req_0)
            4'b0001: bank_r_addr_0 = r_row_1;
            4'b0010: bank_r_addr_0 = r_row_2;
            4'b0100: bank_r_addr_0 = r_row_3;
            4'b1000: bank_r_addr_0 = r_row_4;
            default: bank_r_addr_0 = {BANK_ADDR_WIDTH{1'b0}};
        endcase
    end
    always @(*) begin
        bank_r_addr_1 = {BANK_ADDR_WIDTH{1'b0}};
        case(bank_req_1)
            4'b0001: bank_r_addr_1 = r_row_1;
            4'b0010: bank_r_addr_1 = r_row_2;
            4'b0100: bank_r_addr_1 = r_row_3;
            4'b1000: bank_r_addr_1 = r_row_4;
            default: bank_r_addr_1 = {BANK_ADDR_WIDTH{1'b0}};
        endcase
    end
    always @(*) begin
        bank_r_addr_2 = {BANK_ADDR_WIDTH{1'b0}};
        case(bank_req_2)
            4'b0001: bank_r_addr_2 = r_row_1;
            4'b0010: bank_r_addr_2 = r_row_2;
            4'b0100: bank_r_addr_2 = r_row_3;
            4'b1000: bank_r_addr_2 = r_row_4;
            default: bank_r_addr_2 = {BANK_ADDR_WIDTH{1'b0}};
        endcase
    end
    always @(*) begin
        bank_r_addr_3 = {BANK_ADDR_WIDTH{1'b0}};
        case(bank_req_3)
            4'b0001: bank_r_addr_3 = r_row_1;
            4'b0010: bank_r_addr_3 = r_row_2;
            4'b0100: bank_r_addr_3 = r_row_3;
            4'b1000: bank_r_addr_3 = r_row_4;
            default: bank_r_addr_3 = {BANK_ADDR_WIDTH{1'b0}};
        endcase
    end
    wire [COEFF_WIDTH - 1 : 0] bank_r_data_0, bank_r_data_1, bank_r_data_2, bank_r_data_3;
    assign bank_r_data_0 = bank_0[bank_r_addr_0];
    assign bank_r_data_1 = bank_1[bank_r_addr_1];
    assign bank_r_data_2 = bank_2[bank_r_addr_2];
    assign bank_r_data_3 = bank_3[bank_r_addr_3];
    assign R_data_1 =
        (r_bank_1 == 2'b00) ? bank_r_data_0 : (r_bank_1 == 2'b01) ? bank_r_data_1 : 
        (r_bank_1 == 2'b10) ? bank_r_data_2 : bank_r_data_3;
    assign R_data_2 =
        (r_bank_2 == 2'b00) ? bank_r_data_0 : (r_bank_2 == 2'b01) ? bank_r_data_1:
        (r_bank_2 == 2'b10) ? bank_r_data_2 : bank_r_data_3;
    assign R_data_3 =
        (r_bank_3 == 2'b00) ? bank_r_data_0 : (r_bank_3 == 2'b01) ? bank_r_data_1 :
        (r_bank_3 == 2'b10) ? bank_r_data_2 : bank_r_data_3;
    assign R_data_4 =
        (r_bank_4 == 2'b00) ? bank_r_data_0 : (r_bank_4 == 2'b01) ? bank_r_data_1 :
        (r_bank_4 == 2'b10) ? bank_r_data_2 : bank_r_data_3;
endmodule