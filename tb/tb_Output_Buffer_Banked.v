`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
module tb_Output_Buffer_Banked;

    parameter COEFF_WIDTH = 23;
    parameter DEPTH       = 256;
    parameter ADDR_WIDTH  = 8;


    // ========================================================
    // DUT signals
    // ========================================================

    reg ACLK;

    reg W_EN_1;
    reg W_EN_2;
    reg W_EN_3;
    reg W_EN_4;

    reg [ADDR_WIDTH - 1 : 0] W_addr_1;
    reg [ADDR_WIDTH - 1 : 0] W_addr_2;
    reg [ADDR_WIDTH - 1 : 0] W_addr_3;
    reg [ADDR_WIDTH - 1 : 0] W_addr_4;

    reg [COEFF_WIDTH - 1 : 0] W_data_1;
    reg [COEFF_WIDTH - 1 : 0] W_data_2;
    reg [COEFF_WIDTH - 1 : 0] W_data_3;
    reg [COEFF_WIDTH - 1 : 0] W_data_4;

    reg [ADDR_WIDTH - 1 : 0] R_addr;

    wire [COEFF_WIDTH - 1 : 0] R_data;


    // ========================================================
    // Reference memory
    // ========================================================

    reg [COEFF_WIDTH - 1 : 0] reference_mem [0 : DEPTH - 1];


    integer g;
    integer i;

    integer checks;
    integer errors;


    // ========================================================
    // DUT
    // ========================================================

    Output_Buffer #(
        .COEFF_WIDTH (COEFF_WIDTH),
        .DEPTH       (DEPTH),
        .ADDR_WIDTH  (ADDR_WIDTH)
    ) dut (
        .ACLK     (ACLK),

        .W_EN_1   (W_EN_1),
        .W_EN_2   (W_EN_2),
        .W_EN_3   (W_EN_3),
        .W_EN_4   (W_EN_4),

        .W_addr_1 (W_addr_1),
        .W_addr_2 (W_addr_2),
        .W_addr_3 (W_addr_3),
        .W_addr_4 (W_addr_4),

        .W_data_1 (W_data_1),
        .W_data_2 (W_data_2),
        .W_data_3 (W_data_3),
        .W_data_4 (W_data_4),

        .R_addr   (R_addr),

        .R_data   (R_data)
    );


    // ========================================================
    // Clock
    // ========================================================

    initial begin

        ACLK = 1'b0;

        forever begin
            #5 ACLK = ~ACLK;
        end

    end


    // ========================================================
    // Deterministic test data
    //
    // 7 + 8 + 8 = 23 bits
    // ========================================================

    function [COEFF_WIDTH - 1 : 0] Make_Data;

        input [ADDR_WIDTH - 1 : 0] addr;

        begin

            Make_Data = {
                7'b1010101,
                addr,
                8'hA5
            };

        end

    endfunction


    // ========================================================
    // Check one logical address
    // ========================================================

    task Check_Address;

        input [ADDR_WIDTH - 1 : 0] addr;

        begin

            R_addr = addr;

            #1;


            checks = checks + 1;


            if(R_data !== reference_mem[addr]) begin

                $display(
                    "ERROR: addr=%0d expected=%h actual=%h",
                    addr,
                    reference_mem[addr],
                    R_data
                );

                errors = errors + 1;

            end

        end

    endtask


    // ========================================================
    // Test sequence
    // ========================================================

    initial begin

        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        W_addr_1 = {ADDR_WIDTH{1'b0}};
        W_addr_2 = {ADDR_WIDTH{1'b0}};
        W_addr_3 = {ADDR_WIDTH{1'b0}};
        W_addr_4 = {ADDR_WIDTH{1'b0}};


        W_data_1 = {COEFF_WIDTH{1'b0}};
        W_data_2 = {COEFF_WIDTH{1'b0}};
        W_data_3 = {COEFF_WIDTH{1'b0}};
        W_data_4 = {COEFF_WIDTH{1'b0}};


        R_addr = {ADDR_WIDTH{1'b0}};


        checks = 0;
        errors = 0;


        // ====================================================
        // Phase 1
        //
        // Fill all 256 logical locations using the actual
        // accelerator four-write access pattern.
        //
        // Each cycle:
        //
        //      lane 1 -> 4g + 0
        //      lane 2 -> 4g + 1
        //      lane 3 -> 4g + 2
        //      lane 4 -> 4g + 3
        // ====================================================

        $display("");
        $display("Checking four-way banked writes...");


        for(g = 0; g < 64; g = g + 1) begin

            @(negedge ACLK);


            W_EN_1 = 1'b1;
            W_EN_2 = 1'b1;
            W_EN_3 = 1'b1;
            W_EN_4 = 1'b1;


            W_addr_1 = {g[5:0], 2'b00};
            W_addr_2 = {g[5:0], 2'b01};
            W_addr_3 = {g[5:0], 2'b10};
            W_addr_4 = {g[5:0], 2'b11};


            W_data_1 = Make_Data(
                {g[5:0], 2'b00}
            );

            W_data_2 = Make_Data(
                {g[5:0], 2'b01}
            );

            W_data_3 = Make_Data(
                {g[5:0], 2'b10}
            );

            W_data_4 = Make_Data(
                {g[5:0], 2'b11}
            );


            reference_mem[
                {g[5:0], 2'b00}
            ] = W_data_1;

            reference_mem[
                {g[5:0], 2'b01}
            ] = W_data_2;

            reference_mem[
                {g[5:0], 2'b10}
            ] = W_data_3;

            reference_mem[
                {g[5:0], 2'b11}
            ] = W_data_4;

        end


        @(negedge ACLK);


        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        // ====================================================
        // Phase 2
        //
        // Read all 256 logical addresses sequentially.
        // ====================================================

        $display("");
        $display("Checking sequential reads...");


        for(i = 0; i < DEPTH; i = i + 1) begin

            Check_Address(
                i[ADDR_WIDTH - 1 : 0]
            );

        end


        // ====================================================
        // Phase 3
        //
        // Rewrite one complete four-coefficient group.
        // ====================================================

        $display("");
        $display("Checking overwrite operation...");


        @(negedge ACLK);


        W_EN_1 = 1'b1;
        W_EN_2 = 1'b1;
        W_EN_3 = 1'b1;
        W_EN_4 = 1'b1;


        W_addr_1 = 8'd68;
        W_addr_2 = 8'd69;
        W_addr_3 = 8'd70;
        W_addr_4 = 8'd71;


        W_data_1 = 23'h123456;
        W_data_2 = 23'h234567;
        W_data_3 = 23'h345678;
        W_data_4 = 23'h456789;


        reference_mem[68] = W_data_1;
        reference_mem[69] = W_data_2;
        reference_mem[70] = W_data_3;
        reference_mem[71] = W_data_4;


        @(negedge ACLK);


        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        Check_Address(8'd68);
        Check_Address(8'd69);
        Check_Address(8'd70);
        Check_Address(8'd71);


        // ====================================================
        // Final result
        // ====================================================

        $display("");
        $display("========================================");
        $display("Banked Output Buffer Test Summary");
        $display("========================================");

        $display(
            "Checks : %0d",
            checks
        );

        $display(
            "Errors : %0d",
            errors
        );


        if(errors == 0) begin

            $display("");
            $display(
                "ALL BANKED OUTPUT BUFFER TESTS PASSED"
            );

        end
        else begin

            $display("");
            $display(
                "BANKED OUTPUT BUFFER TEST FAILED"
            );

        end


        $display(
            "========================================"
        );


        $finish;

    end


endmodule
