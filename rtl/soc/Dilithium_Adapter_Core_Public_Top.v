`timescale 1ns / 1ps
// Public release version
// This file exposes only the top-level integration structure and data width.
// Architecture-specific NTT configuration parameters are intentionally omitted.
module Dilithium_Adapter_Core_Public_Top (
    input ACLK,
    input ARESETn,
    input Core_start,
    input Mode_latched,
    output Core_fin,
    output [7 : 0] Input_R_addr_1,
    output [7 : 0] Input_R_addr_2,
    output [7 : 0] Input_R_addr_3,
    output [7 : 0] Input_R_addr_4,
    input [22 : 0] Input_R_data_1,
    input [22 : 0] Input_R_data_2,
    input [22 : 0] Input_R_data_3,
    input [22 : 0] Input_R_data_4,
    output Output_W_EN_1,
    output Output_W_EN_2,
    output Output_W_EN_3,
    output Output_W_EN_4,
    output [7 : 0] Output_W_addr_1,
    output [7 : 0] Output_W_addr_2,
    output [7 : 0] Output_W_addr_3,
    output [7 : 0] Output_W_addr_4,
    output [22 : 0] Output_W_data_1,
    output [22 : 0] Output_W_data_2,
    output [22 : 0] Output_W_data_3,
    output [22 : 0] Output_W_data_4,
    output Dilithium_Start_debug,
    output Dilithium_Mode_debug,
    output Dilithium_Valid_debug,
    output Dilithium_Fin_debug
);
    wire dilithium_rst;
    wire dilithium_start;
    wire dilithium_mode;
    wire [22 : 0] dilithium_data_in_1;
    wire [22 : 0] dilithium_data_in_2;
    wire [22 : 0] dilithium_data_in_3;
    wire [22 : 0] dilithium_data_in_4;
    wire dilithium_valid;
    wire dilithium_fin;
    wire [22 : 0] dilithium_data_out_1;
    wire [22 : 0] dilithium_data_out_2;
    wire [22 : 0] dilithium_data_out_3;
    wire [22 : 0] dilithium_data_out_4;
    // The public version of Dilithium_Core_Adapter exposes only its interface.
    // Internal coefficient ordering, address permutation, input scheduling, output placement, and timing/control details are intentionally omitted.
    Dilithium_Core_Adapter_Public u0_Dilithium_Core_Adapter_Public (
        .ACLK                   (ACLK),
        .ARESETn                (ARESETn),
        .Core_start             (Core_start),
        .Mode_latched           (Mode_latched),
        .Core_fin               (Core_fin),

        .Input_R_addr_1         (Input_R_addr_1),
        .Input_R_addr_2         (Input_R_addr_2),
        .Input_R_addr_3         (Input_R_addr_3),
        .Input_R_addr_4         (Input_R_addr_4),
        .Input_R_data_1         (Input_R_data_1),
        .Input_R_data_2         (Input_R_data_2),
        .Input_R_data_3         (Input_R_data_3),
        .Input_R_data_4         (Input_R_data_4),

        .Output_W_EN_1          (Output_W_EN_1),
        .Output_W_EN_2          (Output_W_EN_2),
        .Output_W_EN_3          (Output_W_EN_3),
        .Output_W_EN_4          (Output_W_EN_4),
        .Output_W_addr_1        (Output_W_addr_1),
        .Output_W_addr_2        (Output_W_addr_2),
        .Output_W_addr_3        (Output_W_addr_3),
        .Output_W_addr_4        (Output_W_addr_4),
        .Output_W_data_1        (Output_W_data_1),
        .Output_W_data_2        (Output_W_data_2),
        .Output_W_data_3        (Output_W_data_3),
        .Output_W_data_4        (Output_W_data_4),

        .Dilithium_Rst          (dilithium_rst),
        .Dilithium_Start        (dilithium_start),
        .Dilithium_Mode         (dilithium_mode),
        .Dilithium_Data_in_1    (dilithium_data_in_1),
        .Dilithium_Data_in_2    (dilithium_data_in_2),
        .Dilithium_Data_in_3    (dilithium_data_in_3),
        .Dilithium_Data_in_4    (dilithium_data_in_4),
        .Dilithium_Valid        (dilithium_valid),
        .Dilithium_Fin          (dilithium_fin),
        .Dilithium_Data_out_1   (dilithium_data_out_1),
        .Dilithium_Data_out_2   (dilithium_data_out_2),
        .Dilithium_Data_out_3   (dilithium_data_out_3),
        .Dilithium_Data_out_4   (dilithium_data_out_4)
    );
    // Only DATA_WIDTH is disclosed in the public source.
    // All remaining architecture-specific configuration parameters are intentionally confidential and therefore omitted here.
    NTT #(
        .DATA_WIDTH (23)
        // CONFIDENTIAL: remaining NTT architecture/configuration parameters are intentionally omitted from the public release.
    ) u1_NTT (
        .Clk        (ACLK),
        .Rst        (dilithium_rst),
        .Start      (dilithium_start),
        .Mode       (dilithium_mode),
        .Data_in_1  (dilithium_data_in_1),
        .Data_in_2  (dilithium_data_in_2),
        .Data_in_3  (dilithium_data_in_3),
        .Data_in_4  (dilithium_data_in_4),
        .Valid      (dilithium_valid),
        .Fin        (dilithium_fin),
        .Data_out_1 (dilithium_data_out_1),
        .Data_out_2 (dilithium_data_out_2),
        .Data_out_3 (dilithium_data_out_3),
        .Data_out_4 (dilithium_data_out_4)
    );
    assign Dilithium_Start_debug = dilithium_start;
    assign Dilithium_Mode_debug  = dilithium_mode;
    assign Dilithium_Valid_debug = dilithium_valid;
    assign Dilithium_Fin_debug   = dilithium_fin;
endmodule
