`timescale 1ns / 1ps
module NTT_AXIL_Regs (
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
    output reg S_AXI_BVALID,
    input S_AXI_BREADY,
    // Control outputs
    output reg Start_pulse,
    output reg Mode,
    output reg [31 : 0] Src_addr,
    output reg [31 : 0] Dst_addr
);
    //AXI4-Lite register address map
    localparam [31:0] ADDR_CONTROL  = 32'h0000_0000;
    localparam [31:0] ADDR_STATUS   = 32'h0000_0004;
    localparam [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    // Write address buffer
    reg [31 : 0] awaddr_reg;
    reg awaddr_pending;
    // Write data buffer
    reg [31 : 0] wdata_reg;
    reg [3 : 0] wstrb_reg;
    reg wdata_pending;
    // AXI ready
    assign S_AXI_AWREADY = !awaddr_pending && !S_AXI_BVALID;
    assign S_AXI_WREADY = !wdata_pending && !S_AXI_BVALID;
    assign S_AXI_BRESP = 2'b00;
    function [31 : 0] Apply_wstrb;
        input [31: 0] Old_data;
        input [31: 0] New_data;
        input [3: 0] Wstrb;
        begin
            Apply_wstrb = Old_data;
            if(Wstrb[0]) Apply_wstrb[7 : 0] = New_data[7 : 0];
            if(Wstrb[1]) Apply_wstrb[15 : 8] = New_data[15 : 8];
            if(Wstrb[2]) Apply_wstrb[23 : 16] = New_data[23 : 16];
            if(Wstrb[3]) Apply_wstrb[31 : 24] = New_data[31 : 24];
        end
    endfunction
    // AXI Write
    always @(posedge ACLK, negedge ARESETn) begin
        if(!ARESETn) begin
            awaddr_reg <= 32'b0;
            awaddr_pending <= 1'b0;
            wdata_reg <= 32'b0;
            wstrb_reg <= 4'b0;
            wdata_pending <= 1'b0;
            S_AXI_BVALID <= 1'b0;
            Start_pulse <= 1'b0;
            Mode <= 1'b0;
            Src_addr <= 32'b0;
            Dst_addr <= 32'b0;
        end
        else begin
            // AW handshake
            Start_pulse <= 1'b0;
            if(S_AXI_AWVALID && S_AXI_AWREADY) begin
                awaddr_reg <= S_AXI_AWADDR;
                awaddr_pending <= 1'b1;
            end
            // W handshake
            if(S_AXI_WVALID && S_AXI_WREADY) begin
                wdata_reg <= S_AXI_WDATA;
                wstrb_reg <= S_AXI_WSTRB;
                wdata_pending <= 1'b1;
            end
            // Write
            if(awaddr_pending && wdata_pending && !S_AXI_BVALID) begin
                case(awaddr_reg)
                    ADDR_CONTROL: begin
                        if(wstrb_reg[0]) begin
                            if(wdata_reg[0]) Start_pulse <= 1'b1;
                            Mode <= wdata_reg[1];
                        end
                    end
                    ADDR_STATUS: ;
                    ADDR_SRC_ADDR: Src_addr <= Apply_wstrb(Src_addr, wdata_reg, wstrb_reg);
                    ADDR_DST_ADDR: Dst_addr <= Apply_wstrb(Dst_addr, wdata_reg, wstrb_reg);
                    default: ;
                endcase
                awaddr_pending <= 1'b0;
                wdata_pending  <= 1'b0;
                S_AXI_BVALID  <= 1'b1;
            end
            // B handshake
            if(S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID <= 1'b0;
        end
    end
endmodule
