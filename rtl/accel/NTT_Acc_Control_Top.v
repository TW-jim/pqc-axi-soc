`timescale 1ns / 1ps
module NTT_Acc_Control_Top (
    // Clock & Reset
    input ACLK,
    input ARESETn,
    // AXI4-L AW
    input [31 : 0] S_AXI_AWADDR,
    input S_AXI_AWVALID,
    output S_AXI_AWREADY,
    // AXI4-L W
    input [31 : 0] S_AXI_WDATA,
    input [3 : 0] S_AXI_WSTRB,
    input S_AXI_WVALID,
    output S_AXI_WREADY,
    // AXI4-L B
    output [1 : 0] S_AXI_BRESP,
    output S_AXI_BVALID,
    input S_AXI_BREADY,
    // AXI4-L AR
    input [31 : 0] S_AXI_ARADDR,
    input S_AXI_ARVALID,
    output S_AXI_ARREADY,
    // AXI4-L R
    output [31 : 0] S_AXI_RDATA,
    output [1 : 0] S_AXI_RRESP,
    output S_AXI_RVALID,
    input S_AXI_RREADY,
    // I/O
    output Load_start,
    input Load_done,
    output Core_start,
    input Core_fin,
    output Write_start,
    input Write_done,
    output Mode_latched,
    output [31 : 0] Src_addr_latched,
    output [31 : 0] Dst_addr_latched,
    output Busy,
    output Done,
    output Error
);
    wire start_pulse_in;
    wire mode_in;
    wire [31 : 0] src_addr_in;
    wire [31 : 0] dst_addr_in;
    NTT_AXIL_Regs u0_NTT_AXIL_Regs (
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
        .Busy(Busy),
        .Done(Done),
        .Error(Error),
        .Start_pulse(start_pulse_in),
        .Mode(mode_in),
        .Src_addr(src_addr_in),
        .Dst_addr(dst_addr_in)
    );
    Acc_Controller u1_Acc_Controller (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .Start_pulse(start_pulse_in),
        .Mode(mode_in),
        .Src_addr(src_addr_in),
        .Dst_addr(dst_addr_in),
        .Load_start(Load_start),
        .Load_done(Load_done),
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
endmodule


