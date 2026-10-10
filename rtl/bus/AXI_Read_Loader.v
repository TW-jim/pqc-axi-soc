`timescale 1ns / 1ps
module AXI_Read_Loader #(
    parameter COEFF_WIDTH = 23
)(
    // Clock & Reset
    input ACLK,
    input ARESETn,
    // Command
    input Load_start,
    input [31 : 0] Base_addr,
    // AXI4 AR
    output reg [31 : 0] M_AXI_ARADDR,
    output [7 : 0] M_AXI_ARLEN,
    output [2 : 0] M_AXI_ARSIZE,
    output [1 : 0] M_AXI_ARBURST,
    output reg M_AXI_ARVALID,
    input M_AXI_ARREADY,
    // AXI4 R
    input [31 : 0] M_AXI_RDATA,
    input [1 : 0] M_AXI_RRESP,
    input M_AXI_RVALID,
    input M_AXI_RLAST,
    output M_AXI_RREADY,
    // Input buffer W
    output Buffer_W_EN,
    output [7 : 0] Buffer_W_addr,
    output [COEFF_WIDTH - 1 : 0] Buffer_W_data,
    // Status
    output reg Load_done,
    output reg Busy,
    output reg Load_error
);
    localparam [7 : 0] AXI_ARLEN_VALUE = 8'h0f;
    localparam [2 : 0] AXI_ARSIZE_VALUE = 3'b010;
    localparam [1 : 0] AXI_ARBURST_INCR = 2'b01;
    assign M_AXI_ARLEN = AXI_ARLEN_VALUE;
    assign M_AXI_ARSIZE = AXI_ARSIZE_VALUE;
    assign M_AXI_ARBURST = AXI_ARBURST_INCR;
    localparam [1 : 0] STATE_IDLE = 2'b00;
    localparam [1 : 0] STATE_SEND_AR = 2'b01;
    localparam [1 : 0] STATE_RECV_R = 2'b10;
    reg [1 : 0] cur_state;
    reg [3 : 0] burst_count;
    reg [4 : 0] beat_count;
    reg [7 : 0] coeff_count;
    assign M_AXI_RREADY = cur_state == STATE_RECV_R;
    assign Buffer_W_EN = M_AXI_RVALID && M_AXI_RREADY;
    assign Buffer_W_addr = coeff_count;
    assign Buffer_W_data = M_AXI_RDATA[COEFF_WIDTH - 1 : 0];
    wire rdata_upper_nonzero;
    assign rdata_upper_nonzero = |M_AXI_RDATA[31 : COEFF_WIDTH];
    always @(posedge ACLK, negedge ARESETn) begin
        if(!ARESETn) begin
            cur_state <= STATE_IDLE;
            burst_count <= 4'b0000;
            beat_count <= 5'b0_0000;
            coeff_count <= 8'h00;
            M_AXI_ARADDR <= 32'b0;
            M_AXI_ARVALID <= 1'b0;
            Load_done <= 1'b0;
            Load_error <= 1'b0;
            Busy <= 1'b0;
        end
        else begin
            Load_done <= 1'b0;
            case(cur_state)
                STATE_IDLE: begin
                    Busy <= 1'b0;
                    M_AXI_ARVALID <= 1'b0;
                    if(Load_start) begin
                        burst_count <= 4'b0000;
                        beat_count <= 5'b0_0000;
                        coeff_count <= 8'h00;
                        M_AXI_ARADDR <= Base_addr;
                        M_AXI_ARVALID <= 1'b1;
                        Busy <= 1'b1;
                        Load_error <= 1'b0;
                        cur_state <= STATE_SEND_AR;
                    end
                end
                STATE_SEND_AR: begin
                    Busy <= 1'b1;
                    M_AXI_ARVALID <= 1'b1;
                    if(M_AXI_ARREADY && M_AXI_ARVALID) begin
                        M_AXI_ARVALID <= 1'b0;
                        beat_count <= 5'b0_0000;
                        cur_state <= STATE_RECV_R;
                    end
                end
                STATE_RECV_R: begin
                    Busy <= 1'b1;
                    M_AXI_ARVALID <= 1'b0;
                    if(M_AXI_RREADY && M_AXI_RVALID) begin
                        if(M_AXI_RRESP != 2'b00) Load_error <= 1'b1;
                        if(rdata_upper_nonzero) Load_error <= 1'b1;
                        if(beat_count < 5'b0_1111) begin
                            if(M_AXI_RLAST) begin
                                Load_error <= 1'b1;
                                Busy <= 1'b0;
                                cur_state <= STATE_IDLE;
                            end
                            else begin
                                beat_count <= beat_count + 1'b1;
                                coeff_count <= coeff_count + 1'b1;
                            end
                        end
                        else if(beat_count == 5'b0_1111) begin
                            if(!M_AXI_RLAST) begin
                                Load_error <= 1'b1;
                                Busy <= 1'b0;
                                cur_state <= STATE_IDLE;
                            end
                            else begin
                                coeff_count <= coeff_count + 1'b1;
                                if(burst_count == 4'b1111) begin
                                    Busy <= 1'b0;
                                    Load_done <= 1'b1;
                                    cur_state <= STATE_IDLE;
                                end
                                else begin
                                    burst_count <= burst_count + 1'b1;
                                    M_AXI_ARADDR <= M_AXI_ARADDR + 32'h0000_0040;
                                    M_AXI_ARVALID <= 1'b1;
                                    cur_state <= STATE_SEND_AR;
                                end
                                beat_count <= 5'b0_0000;
                            end
                        end
                        else begin
                            Load_error <= 1'b1;
                            Busy <= 1'b0;
                            cur_state <= STATE_IDLE;
                        end
                    end
                end
                default: begin
                    cur_state <= STATE_IDLE;
                    burst_count <= 4'b0000;
                    beat_count <= 5'b0_0000;
                    coeff_count <= 8'h00;
                    M_AXI_ARADDR <= 32'b0;
                    M_AXI_ARVALID <= 1'b0;
                    Busy <= 1'b0;
                    Load_done <= 1'b0;
                    Load_error <= 1'b1;
                end
            endcase
        end
    end
endmodule
