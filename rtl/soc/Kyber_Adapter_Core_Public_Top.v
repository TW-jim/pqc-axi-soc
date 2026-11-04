`timescale 1ns / 1ps
// Public release version
// This file exposes only the top-level integration structure and data width.
// Architecture-specific NTT configuration parameters are intentionally omitted
module Kyber_Adapter_Core_Public_Top (
    input ACLK,
    input ARESETn,
    input Core_start,
    input Mode_latched,
    output Core_fin,
    output [7 : 0] Input_R_addr_1,
    output [7 : 0] Input_R_addr_2,
    output [7 : 0] Input_R_addr_3,
    output [7 : 0] Input_R_addr_4,
    input [11 : 0] Input_R_data_1,
    input [11 : 0] Input_R_data_2,
    input [11 : 0] Input_R_data_3,
    input [11 : 0] Input_R_data_4,
    output Output_W_EN_1,
    output Output_W_EN_2,
    output Output_W_EN_3,
    output Output_W_EN_4,
    output [7 : 0] Output_W_addr_1,
    output [7 : 0] Output_W_addr_2,
    output [7 : 0] Output_W_addr_3,
    output [7 : 0] Output_W_addr_4,
    output [11 : 0] Output_W_data_1,
    output [11 : 0] Output_W_data_2,
    output [11 : 0] Output_W_data_3,
    output [11 : 0] Output_W_data_4,
    output Kyber_Start_debug,
    output Kyber_Mode_debug,
    output Kyber_Valid_debug,
    output Kyber_Fin_debug
);
    wire kyber_rst;
    wire kyber_start;
    wire kyber_mode;
    wire [11 : 0] kyber_data_in_1;
    wire [11 : 0] kyber_data_in_2;
    wire [11 : 0] kyber_data_in_3;
    wire [11 : 0] kyber_data_in_4;
    wire kyber_valid;
    wire kyber_fin;
    wire [11 : 0] kyber_data_out_1;
    wire [11 : 0] kyber_data_out_2;
    wire [11 : 0] kyber_data_out_3;
    wire [11 : 0] kyber_data_out_4;
    // The public version of Dilithium_Core_Adapter exposes only its interface.
    // Internal coefficient ordering, address permutation, input scheduling, output placement, and timing/control details are intentionally omitted.
    Kyber_Core_Adapter_Public u0_Kyber_Core_Adapter_Public (
        .ACLK               (ACLK),
        .ARESETn            (ARESETn),
        .Core_start         (Core_start),
        .Mode_latched       (Mode_latched),
        .Core_fin           (Core_fin),
        .Input_R_addr_1     (Input_R_addr_1),
        .Input_R_addr_2     (Input_R_addr_2),
        .Input_R_addr_3     (Input_R_addr_3),
        .Input_R_addr_4     (Input_R_addr_4),
        .Input_R_data_1     (Input_R_data_1),
        .Input_R_data_2     (Input_R_data_2),
        .Input_R_data_3     (Input_R_data_3),
        .Input_R_data_4     (Input_R_data_4),
        .Output_W_EN_1      (Output_W_EN_1),
        .Output_W_EN_2      (Output_W_EN_2),
        .Output_W_EN_3      (Output_W_EN_3),
        .Output_W_EN_4      (Output_W_EN_4),
        .Output_W_addr_1    (Output_W_addr_1),
        .Output_W_addr_2    (Output_W_addr_2),
        .Output_W_addr_3    (Output_W_addr_3),
        .Output_W_addr_4    (Output_W_addr_4),
        .Output_W_data_1    (Output_W_data_1),
        .Output_W_data_2    (Output_W_data_2),
        .Output_W_data_3    (Output_W_data_3),
        .Output_W_data_4    (Output_W_data_4),
        .Kyber_Rst          (kyber_rst),
        .Kyber_Start        (kyber_start),
        .Kyber_Mode         (kyber_mode),
        .Kyber_Data_in_1    (kyber_data_in_1),
        .Kyber_Data_in_2    (kyber_data_in_2),
        .Kyber_Data_in_3    (kyber_data_in_3),
        .Kyber_Data_in_4    (kyber_data_in_4),
        .Kyber_Valid        (kyber_valid),
        .Kyber_Fin          (kyber_fin),
        .Kyber_Data_out_1   (kyber_data_out_1),
        .Kyber_Data_out_2   (kyber_data_out_2),
        .Kyber_Data_out_3   (kyber_data_out_3),
        .Kyber_Data_out_4   (kyber_data_out_4)
    );
    // Only DATA_WIDTH is disclosed in the public source.
    // All remaining architecture-specific configuration parameters are intentionally confidential and therefore omitted here.
    NTT #(
        .DATA_WIDTH (12)
        // CONFIDENTIAL: remaining NTT architecture/configuration parameters are intentionally omitted from the public release.
    ) u1_NTT (
        .Clk        (ACLK),
        .Rst        (kyber_rst),
        .Start      (kyber_start),
        .Mode       (kyber_mode),
        .Data_in_1  (kyber_data_in_1),
        .Data_in_2  (kyber_data_in_2),
        .Data_in_3  (kyber_data_in_3),
        .Data_in_4  (kyber_data_in_4),
        .Valid      (kyber_valid),
        .Fin        (kyber_fin),
        .Data_out_1 (kyber_data_out_1),
        .Data_out_2 (kyber_data_out_2),
        .Data_out_3 (kyber_data_out_3),
        .Data_out_4 (kyber_data_out_4)
    );
    assign Kyber_Start_debug = kyber_start;
    assign Kyber_Mode_debug  = kyber_mode;
    assign Kyber_Valid_debug = kyber_valid;
    assign Kyber_Fin_debug   = kyber_fin;
endmodule
