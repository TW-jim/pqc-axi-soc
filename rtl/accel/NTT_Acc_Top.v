`timescale 1ns / 1ps
module NTT_Acc_Top #(
    parameter COEFF_WIDTH = 23
)(
    // Clock & Reset
    input ACLK,
    input ARESETn,
    // AXI4-L Slave
    // AW
    input [31 : 0] S_AXI_AWADDR,
    input S_AXI_AWVALID,
    output S_AXI_AWREADY,
    // W
    input [31 : 0] S_AXI_WDATA,
    input [3 : 0] S_AXI_WSTRB,
    input S_AXI_WVALID,
    output S_AXI_WREADY,
    // B
    output [1 : 0] S_AXI_BRESP,
    output S_AXI_BVALID,
    input S_AXI_BREADY,
    // AR
    input [31 : 0] S_AXI_ARADDR,
    input S_AXI_ARVALID,
    output S_AXI_ARREADY,
    // R
    output [31 : 0] S_AXI_RDATA,
    output [1 : 0] S_AXI_RRESP,
    output S_AXI_RVALID,
    input S_AXI_RREADY,
    //AXI4 Master
    // AW
    output [31 : 0] M_AXI_AWADDR,
    output [7 : 0] M_AXI_AWLEN,
    output [2 : 0] M_AXI_AWSIZE,
    output [1 : 0] M_AXI_AWBURST,
    output M_AXI_AWVALID,
    input M_AXI_AWREADY,
    // W
    output [31 : 0] M_AXI_WDATA,
    output [3 : 0] M_AXI_WSTRB,
    output M_AXI_WLAST,
    output M_AXI_WVALID,
    input M_AXI_WREADY,
    // B
    input [1 : 0] M_AXI_BRESP,
    input M_AXI_BVALID,
    output M_AXI_BREADY,
    // AR
    output [31 : 0] M_AXI_ARADDR,
    output [7 : 0] M_AXI_ARLEN,
    output [2 : 0] M_AXI_ARSIZE,
    output [1 : 0] M_AXI_ARBURST,
    output M_AXI_ARVALID,
    input M_AXI_ARREADY,
    // R
    input [31 : 0] M_AXI_RDATA,
    input [1 : 0] M_AXI_RRESP,
    input M_AXI_RVALID,
    input M_AXI_RLAST,
    output M_AXI_RREADY,
    // I/O & status
    output Core_start,
    input Core_fin,
    input [7 : 0] Input_R_addr_1,
    input [7 : 0] Input_R_addr_2,
    input [7 : 0] Input_R_addr_3,
    input [7 : 0] Input_R_addr_4,
    output [COEFF_WIDTH - 1 : 0] Input_R_data_1,
    output [COEFF_WIDTH - 1 : 0] Input_R_data_2,
    output [COEFF_WIDTH - 1 : 0] Input_R_data_3,
    output [COEFF_WIDTH - 1 : 0] Input_R_data_4,
    input Output_W_EN_1,
    input Output_W_EN_2,
    input Output_W_EN_3,
    input Output_W_EN_4,
    input [7 : 0] Output_W_addr_1,
    input [7 : 0] Output_W_addr_2,
    input [7 : 0] Output_W_addr_3,
    input [7 : 0] Output_W_addr_4,
    input [COEFF_WIDTH - 1 : 0] Output_W_data_1,
    input [COEFF_WIDTH - 1 : 0] Output_W_data_2,
    input [COEFF_WIDTH - 1 : 0] Output_W_data_3,
    input [COEFF_WIDTH - 1 : 0] Output_W_data_4,
    output Busy,
    output Done,
    output Error,
    output Load_busy,
    output Load_error,
    output Write_busy,
    output Write_error,
    output Mode_latched,
    output [31 : 0] Src_addr_latched,
    output [31 : 0] Dst_addr_latched
);
    wire load_start_in, load_done_in;
    wire write_start_in, write_done_in;
    wire input_buffer_w_en;
    wire [7 : 0] input_buffer_w_addr, output_buffer_r_addr;
    wire [COEFF_WIDTH - 1 : 0] input_buffer_w_data, output_buffer_r_data;
    NTT_Acc_Control_Top u0_NTT_ACC_Control_Top (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .Load_start(load_start_in),
        .Load_done(load_done_in),
        .Core_start(Core_start),
        .Core_fin(Core_fin),
        .Write_start(write_start_in),
        .Write_done(write_done_in),
        .Mode_latched(Mode_latched),
        .Src_addr_latched(Src_addr_latched),
        .Dst_addr_latched(Dst_addr_latched),
        .Busy(Busy),
        .Done(Done),
        .Error(Error)
    );
    AXI_Read_Loader #(
        .COEFF_WIDTH(COEFF_WIDTH)
    ) u1_AXI_Read_Loader (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .Load_start(load_start_in),
        .Base_addr(Src_addr_latched),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RREADY(M_AXI_RREADY),
        .Buffer_W_EN(input_buffer_w_en),
        .Buffer_W_addr(input_buffer_w_addr),
        .Buffer_W_data(input_buffer_w_data),
        .Load_done(load_done_in),
        .Busy(Load_busy),
        .Load_error(Load_error)
    );
    Input_Buffer #(
        .COEFF_WIDTH(COEFF_WIDTH),
        .DEPTH(256),
        .ADDR_WIDTH(8)
    ) u3_Input_Buffer (
        .ACLK(ACLK),
        .W_EN(input_buffer_w_en),
        .W_addr(input_buffer_w_addr),
        .W_data(input_buffer_w_data),
        .R_addr_1(Input_R_addr_1),
        .R_addr_2(Input_R_addr_2),
        .R_addr_3(Input_R_addr_3),
        .R_addr_4(Input_R_addr_4),
        .R_data_1(Input_R_data_1),
        .R_data_2(Input_R_data_2),
        .R_data_3(Input_R_data_3),
        .R_data_4(Input_R_data_4)
    );
    Output_Buffer #(
        .COEFF_WIDTH(COEFF_WIDTH),
        .DEPTH(256),
        .ADDR_WIDTH(8)
    ) u4_Output_Buffer (
        .ACLK(ACLK),
        .W_EN_1(Output_W_EN_1),
        .W_EN_2(Output_W_EN_2),
        .W_EN_3(Output_W_EN_3),
        .W_EN_4(Output_W_EN_4),
        .W_addr_1(Output_W_addr_1),
        .W_addr_2(Output_W_addr_2),
        .W_addr_3(Output_W_addr_3),
        .W_addr_4(Output_W_addr_4),
        .W_data_1(Output_W_data_1),
        .W_data_2(Output_W_data_2),
        .W_data_3(Output_W_data_3),
        .W_data_4(Output_W_data_4),
        .R_addr(output_buffer_r_addr),
        .R_data(output_buffer_r_data)
    );
    AXI_Write_Writer #(
        .COEFF_WIDTH(COEFF_WIDTH)
    ) u5_AXI_Write_Writer (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .Write_start(write_start_in),
        .Base_addr(Dst_addr_latched),
        .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWLEN(M_AXI_AWLEN),
        .M_AXI_AWSIZE(M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_WDATA(M_AXI_WDATA),
        .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_WVALID(M_AXI_WVALID),
        .M_AXI_WREADY(M_AXI_WREADY),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(M_AXI_BREADY),
        .Buffer_R_addr(output_buffer_r_addr),
        .Buffer_R_data(output_buffer_r_data),
        .Write_done(write_done_in),
        .Busy(Write_busy),
        .Write_error(Write_error)
    );
endmodule
