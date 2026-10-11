`timescale 1ns / 1ps
module AXI_Write_Writer #(
    parameter COEFF_WIDTH = 23
)(
    // Clock & Reset
    input ACLK,
    input ARESETn,
    // Command
    input Write_start,
    input [31 : 0] Base_addr,
    // AXI4 AW
    output reg [31 : 0] M_AXI_AWADDR,
    output [7 : 0] M_AXI_AWLEN,
    output [2 : 0] M_AXI_AWSIZE,
    output [1 : 0] M_AXI_AWBURST,
    output reg M_AXI_AWVALID,
    input M_AXI_AWREADY,
    // AXI4 W
    output [31 : 0] M_AXI_WDATA,
    output [3 : 0] M_AXI_WSTRB,
    output M_AXI_WLAST,
    output M_AXI_WVALID,
    input M_AXI_WREADY,
    // AXI4 B
    input [1 : 0] M_AXI_BRESP,
    input M_AXI_BVALID,
    output M_AXI_BREADY,
    // Buffer & status
    output [7 : 0] Buffer_R_addr,
    input [COEFF_WIDTH - 1 : 0] Buffer_R_data,
    output reg Write_done,
    output reg Busy,
    output reg Write_error
);
    localparam [7 : 0] AXI_AWLEN_VALUE = 8'h0f;
    localparam [2 : 0] AXI_AWSIZE_VALUE = 3'b010;
    localparam [1 : 0] AXI_AWBURST_INCR = 2'b01;
    assign M_AXI_AWLEN = AXI_AWLEN_VALUE;
    assign M_AXI_AWSIZE = AXI_AWSIZE_VALUE;
    assign M_AXI_AWBURST = AXI_AWBURST_INCR;
    localparam [1 : 0] STATE_IDLE = 2'b00;
    localparam [1 : 0] STATE_SEND_AW = 2'b01;
    localparam [1 : 0] STATE_SEND_W = 2'b10;
    localparam [1 : 0] STATE_WAIT_B = 2'b11;
    reg [1 : 0] cur_state;
    reg [3 : 0] burst_count, beat_count;
    reg [7 : 0] coeff_count;
    assign Buffer_R_addr = coeff_count;
    assign M_AXI_WDATA = {{(32 - COEFF_WIDTH){1'b0}}, Buffer_R_data};
    assign M_AXI_WSTRB = 4'b1111;
    assign M_AXI_WVALID = cur_state == STATE_SEND_W;
    assign M_AXI_WLAST = (cur_state == STATE_SEND_W) && (beat_count == 4'b1111);
    assign M_AXI_BREADY = cur_state == STATE_WAIT_B;
    always @(posedge ACLK, negedge ARESETn) begin
        if(!ARESETn) begin
            cur_state <= STATE_IDLE;
            burst_count <= 4'b0000;
            beat_count <= 4'b0000;
            coeff_count <= 8'h00;
            M_AXI_AWADDR <= 32'h0000_0000;
            M_AXI_AWVALID <= 1'b0;
            Write_done <= 1'b0;
            Write_error <= 1'b0;
            Busy <= 1'b0;
        end
        else begin
            Write_done <= 1'b0;
            case(cur_state)
                STATE_IDLE: begin
                    Busy <= 1'b0;
                    M_AXI_AWVALID <= 1'b0;
                    if(Write_start) begin
                        Busy <= 1'b1;
                        burst_count <= 4'b0000;
                        beat_count <= 4'b0000;
                        coeff_count <= 8'h00;
                        Write_error <= 1'b0;
                        M_AXI_AWADDR <= Base_addr;
                        M_AXI_AWVALID <= 1'b1;
                        cur_state <= STATE_SEND_AW;
                    end
                end
                STATE_SEND_AW: begin
                    Busy <= 1'b1;
                    M_AXI_AWVALID <= 1'b1;
                    if(M_AXI_AWVALID && M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 1'b0;
                        beat_count <= 4'b0000;
                        cur_state <= STATE_SEND_W;
                    end
                end
                STATE_SEND_W: begin
                    Busy <= 1'b1;
                    M_AXI_AWVALID <= 1'b0;
                    if(M_AXI_WVALID && M_AXI_WREADY) begin
                        coeff_count <= coeff_count + 1'b1;
                        if(beat_count == 4'b1111) begin
                            beat_count <= 4'b0000;
                            cur_state <= STATE_WAIT_B;
                        end
                        else beat_count <= beat_count + 1'b1;
                    end
                end
                STATE_WAIT_B: begin
                    Busy <= 1'b1;
                    M_AXI_AWVALID <= 1'b0;
                    if(M_AXI_BVALID && M_AXI_BREADY) begin
                        if(M_AXI_BRESP != 2'b00) Write_error <= 1'b1;
                        if(burst_count == 4'b1111) begin
                            Busy <= 1'b0;
                            Write_done <= 1'b1;
                            cur_state <= STATE_IDLE;
                        end
                        else begin
                            burst_count <= burst_count + 1'b1;
                            M_AXI_AWADDR <= M_AXI_AWADDR + 32'h0000_0040;
                            cur_state <= STATE_SEND_AW;
                        end
                    end
                end
                default: begin
                    cur_state <= STATE_IDLE;
                    burst_count <= 4'b0000;
                    beat_count <= 4'b0000;
                    coeff_count <= 8'h00;
                    M_AXI_AWADDR <= 32'h0000_0000;
                    M_AXI_AWVALID <= 1'b0;
                    Busy <= 1'b0;
                    Write_done <= 1'b0;
                    Write_error <= 1'b1;
                end
            endcase
        end
    end
endmodule
