interface AXIL_if (
    input logic ACLK,
    input logic ARESETn
);
    logic [31:0] S_AXI_AWADDR;
    logic S_AXI_AWVALID;
    logic S_AXI_AWREADY;
    logic [31:0] S_AXI_WDATA;
    logic [3:0] S_AXI_WSTRB;
    logic S_AXI_WVALID;
    logic S_AXI_WREADY;
    logic [1:0] S_AXI_BRESP;
    logic S_AXI_BVALID;
    logic S_AXI_BREADY;
    logic [31:0] S_AXI_ARADDR;
    logic S_AXI_ARVALID;
    logic S_AXI_ARREADY;
    logic [31:0] S_AXI_RDATA;
    logic [1:0] S_AXI_RRESP;
    logic S_AXI_RVALID;
    logic S_AXI_RREADY;
    logic Busy;
    logic Done;
    logic Error;
    logic Start_pulse;
    logic Mode;
    logic [31:0] Src_addr;
    logic [31:0] Dst_addr;
    logic tb_reset_req = 1'b0;
endinterface
