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
    output Write_start,
    input Write_done,
    input [7 : 0] Buffer_R_addr_1,
    input [7 : 0] Buffer_R_addr_2,
    input [7 : 0] Buffer_R_addr_3,
    input [7 : 0] Buffer_R_addr_4,
    output [COEFF_WIDTH - 1 : 0] Buffer_R_data_1,
    output [COEFF_WIDTH - 1 : 0] Buffer_R_data_2,
    output [COEFF_WIDTH - 1 : 0] Buffer_R_data_3,
    output [COEFF_WIDTH - 1 : 0] Buffer_R_data_4,
    output Busy,
    output Done,
    output Error,
    output Load_busy,
    output Load_error,
    output Mode_latched,
    output [31 : 0] Src_addr_latched,
    output [31 : 0] Dst_addr_latched
);
    wire load_start_in, load_done_in;
    wire buffer_w_en;
    wire [7 : 0] buffer_w_addr;
    wire [COEFF_WIDTH - 1 : 0] buffer_w_data;
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
        .Write_start(Write_start),
        .Write_done(Write_done),
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
        .Buffer_W_EN(buffer_w_en),
        .Buffer_W_addr(buffer_w_addr),
        .Buffer_W_data(buffer_w_data),
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
        .W_EN(buffer_w_en),
        .W_addr(buffer_w_addr),
        .W_data(buffer_w_data),
        .R_addr_1(Buffer_R_addr_1),
        .R_addr_2(Buffer_R_addr_2),
        .R_addr_3(Buffer_R_addr_3),
        .R_addr_4(Buffer_R_addr_4),
        .R_data_1(Buffer_R_data_1),
        .R_data_2(Buffer_R_data_2),
        .R_data_3(Buffer_R_data_3),
        .R_data_4(Buffer_R_data_4)
    );
endmodule
