`timescale 1ns / 1ps
module tb_Top;
    import uvm_pkg::*;
    import AXIL_Pkg::*;
    // Clock / Reset
    logic ACLK;
    logic ARESETn;
    logic initial_reset_n;
    // AXI-Lite Interface
    AXIL_if axil_vif (
        .ACLK (ACLK),
        .ARESETn (ARESETn)
    );
    // DUT
    NTT_AXIL_Regs DUT (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .S_AXI_AWADDR(axil_vif.S_AXI_AWADDR),
        .S_AXI_AWVALID(axil_vif.S_AXI_AWVALID),
        .S_AXI_AWREADY(axil_vif.S_AXI_AWREADY),
        .S_AXI_WDATA(axil_vif.S_AXI_WDATA),
        .S_AXI_WSTRB(axil_vif.S_AXI_WSTRB),
        .S_AXI_WVALID(axil_vif.S_AXI_WVALID),
        .S_AXI_WREADY(axil_vif.S_AXI_WREADY),
        .S_AXI_BRESP(axil_vif.S_AXI_BRESP),
        .S_AXI_BVALID(axil_vif.S_AXI_BVALID),
        .S_AXI_BREADY(axil_vif.S_AXI_BREADY),
        .S_AXI_ARADDR(axil_vif.S_AXI_ARADDR),
        .S_AXI_ARVALID(axil_vif.S_AXI_ARVALID),
        .S_AXI_ARREADY(axil_vif.S_AXI_ARREADY),
        .S_AXI_RDATA(axil_vif.S_AXI_RDATA),
        .S_AXI_RRESP(axil_vif.S_AXI_RRESP),
        .S_AXI_RVALID(axil_vif.S_AXI_RVALID),
        .S_AXI_RREADY(axil_vif.S_AXI_RREADY),
        .Busy(axil_vif.Busy),
        .Done(axil_vif.Done),
        .Error(axil_vif.Error),
        .Start_pulse(axil_vif.Start_pulse),
        .Mode(axil_vif.Mode),
        .Src_addr(axil_vif.Src_addr),
        .Dst_addr(axil_vif.Dst_addr)
    );
    // Clock
    initial begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end
    assign ARESETn = initial_reset_n && !axil_vif.tb_reset_req;
    // Reset / accelerator status
    initial begin
        initial_reset_n = 1'b0;
        axil_vif.Busy = 1'b0;
        axil_vif.Done = 1'b0;
        axil_vif.Error = 1'b0;
        repeat(5)
            @(posedge ACLK);
        @(negedge ACLK);
        initial_reset_n = 1'b1;
    end
    // UVM
    initial begin
        uvm_config_db #(virtual AXIL_if)::set(null, "*", "vif", axil_vif);
        run_test();
    end
endmodule
