`timescale 1ns / 1ps
module Acc_Controller (
    input ACLK,
    input ARESETn,
    input Start_pulse,
    input Mode,
    input [31 : 0] Src_addr,
    input [31 : 0] Dst_addr,
    output reg Load_start,
    input Load_done,
    output reg Core_start,
    input Core_fin,
    output reg Write_start,
    input Write_done,
    output reg Mode_latched,
    output reg [31 : 0] Src_addr_latched,
    output reg [31 : 0] Dst_addr_latched,
    output reg Busy,
    output reg Done,
    output reg Error
);
    localparam [2 : 0] STATE_IDLE = 3'b000;
    localparam [2 : 0] STATE_LOAD_INPUT = 3'b001;
    localparam [2 : 0] STATE_PREP_CORE = 3'b010;
    localparam [2 : 0] STATE_RUN_CORE = 3'b011;
    localparam [2 : 0] STATE_PREP_WRITE = 3'b100;
    localparam [2 : 0] STATE_WRITE_OUTPUT = 3'b101;
    reg [2 : 0] cur_state;
    always @(posedge ACLK, negedge ARESETn) begin
        if(!ARESETn) begin
            cur_state <= STATE_IDLE;
            Load_start <= 1'b0;
            Core_start <= 1'b0;
            Write_start <= 1'b0;
            Mode_latched <= 1'b0;
            Src_addr_latched <= 32'b0;
            Dst_addr_latched <= 32'b0;
            Busy <= 1'b0;
            Done <= 1'b0;
            Error <= 1'b0;
        end
        else begin
            Load_start <= 1'b0;
            Core_start <= 1'b0;
            Write_start <= 1'b0;
            case(cur_state)
                STATE_IDLE: begin
                    Busy <= 1'b0;
                    if(Start_pulse) begin
                        Mode_latched <= Mode;
                        Src_addr_latched <= Src_addr;
                        Dst_addr_latched <= Dst_addr;
                        Busy <= 1'b1;
                        Done <= 1'b0;
                        Error <= 1'b0;
                        Load_start <= 1'b1;
                        cur_state <= STATE_LOAD_INPUT;
                    end
                end
                STATE_LOAD_INPUT: begin
                    Busy <= 1'b1;
                    if(Load_done) cur_state <= STATE_PREP_CORE;
                end
                STATE_PREP_CORE: begin
                    Busy <= 1'b1;
                    Core_start <= 1'b1;
                    cur_state <= STATE_RUN_CORE;
                end
                STATE_RUN_CORE: begin
                    Busy <= 1'b1;
                    if(Core_fin) cur_state <= STATE_PREP_WRITE;
                end
                STATE_PREP_WRITE: begin
                    Busy <= 1'b1;
                    Write_start <= 1'b1;
                    cur_state <= STATE_WRITE_OUTPUT;
                end
                STATE_WRITE_OUTPUT: begin
                    Busy <= 1'b1;
                    if(Write_done) begin
                        Busy <= 1'b0;
                        Done <= 1'b1;
                        cur_state <= STATE_IDLE;
                    end
                end
                default: begin
                    cur_state <= STATE_IDLE;
                    Busy <= 1'b0;
                    Done <= 1'b0;
                    Error <= 1'b1;
                end
            endcase
        end
    end
endmodule
