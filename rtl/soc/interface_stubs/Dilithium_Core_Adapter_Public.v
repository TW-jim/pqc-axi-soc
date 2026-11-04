`timescale 1ns / 1ps
// PUBLIC INTERFACE STUB
// The production implementation of this adapter is intentionally NOT included in the public repository.
// CONFIDENTIAL IMPLEMENTATION DETAILS INCLUDE, BUT ARE NOT LIMITED TO:
//   - coefficient/data ordering
//   - NTT/INTT address permutation
//   - input feed scheduling
//   - output placement/reordering
//   - internal counters and control-state sequencing
//   - timing relationships used by the private NTT datapath
// This module exists only to document the integration interface. It is NOT a functional replacement for the private adapter implementation.
module Dilithium_Core_Adapter_Public (
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
    output Dilithium_Rst,
    output Dilithium_Start,
    output Dilithium_Mode,
    output [22 : 0] Dilithium_Data_in_1,
    output [22 : 0] Dilithium_Data_in_2,
    output [22 : 0] Dilithium_Data_in_3,
    output [22 : 0] Dilithium_Data_in_4,
    input Dilithium_Valid,
    input Dilithium_Fin,
    input [22 : 0] Dilithium_Data_out_1,
    input [22 : 0] Dilithium_Data_out_2,
    input [22 : 0] Dilithium_Data_out_3,
    input [22 : 0] Dilithium_Data_out_4
);
    // CONFIDENTIAL IMPLEMENTATION OMITTED
    // Drive unknown values deliberately so this interface stub cannot be mistaken for a functional behavioral model during simulation.
    assign Core_fin             = 1'bx;
    assign Input_R_addr_1       = 8'hxx;
    assign Input_R_addr_2       = 8'hxx;
    assign Input_R_addr_3       = 8'hxx;
    assign Input_R_addr_4       = 8'hxx;
    assign Output_W_EN_1        = 1'bx;
    assign Output_W_EN_2        = 1'bx;
    assign Output_W_EN_3        = 1'bx;
    assign Output_W_EN_4        = 1'bx;
    assign Output_W_addr_1      = 8'hxx;
    assign Output_W_addr_2      = 8'hxx;
    assign Output_W_addr_3      = 8'hxx;
    assign Output_W_addr_4      = 8'hxx;
    assign Output_W_data_1      = 23'hxxxxxx;
    assign Output_W_data_2      = 23'hxxxxxx;
    assign Output_W_data_3      = 23'hxxxxxx;
    assign Output_W_data_4      = 23'hxxxxxx;
    assign Dilithium_Rst        = 1'bx;
    assign Dilithium_Start      = 1'bx;
    assign Dilithium_Mode       = 1'bx;
    assign Dilithium_Data_in_1  = 23'hxxxxxx;
    assign Dilithium_Data_in_2  = 23'hxxxxxx;
    assign Dilithium_Data_in_3  = 23'hxxxxxx;
    assign Dilithium_Data_in_4  = 23'hxxxxxx;
endmodule
