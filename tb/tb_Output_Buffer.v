`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
module tb_Output_Buffer;


    localparam COEFF_WIDTH = 23;


    reg ACLK;


    // Write port 1
    reg W_EN_1;
    reg [7:0] W_addr_1;
    reg [COEFF_WIDTH-1:0] W_data_1;

    // Write port 2
    reg W_EN_2;
    reg [7:0] W_addr_2;
    reg [COEFF_WIDTH-1:0] W_data_2;

    // Write port 3
    reg W_EN_3;
    reg [7:0] W_addr_3;
    reg [COEFF_WIDTH-1:0] W_data_3;

    // Write port 4
    reg W_EN_4;
    reg [7:0] W_addr_4;
    reg [COEFF_WIDTH-1:0] W_data_4;


    // Read
    reg [7:0] R_addr;
    wire [COEFF_WIDTH-1:0] R_data;


    integer test_count;
    integer error_count;


    //==================================================================
    // DUT
    //==================================================================

    Output_Buffer #(

        .COEFF_WIDTH(COEFF_WIDTH),
        .DEPTH(256),
        .ADDR_WIDTH(8)

    ) DUT (

        .ACLK       (ACLK),

        .W_EN_1     (W_EN_1),
        .W_addr_1   (W_addr_1),
        .W_data_1   (W_data_1),

        .W_EN_2     (W_EN_2),
        .W_addr_2   (W_addr_2),
        .W_data_2   (W_data_2),

        .W_EN_3     (W_EN_3),
        .W_addr_3   (W_addr_3),
        .W_data_3   (W_data_3),

        .W_EN_4     (W_EN_4),
        .W_addr_4   (W_addr_4),
        .W_data_4   (W_data_4),

        .R_addr     (R_addr),
        .R_data     (R_data)
    );


    //==================================================================
    // Clock
    //==================================================================

    initial begin

        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;

    end


    //==================================================================
    // Waveform
    //==================================================================

    initial begin

        $dumpfile("Output_Buffer_tb.vcd");
        $dumpvars(0, tb_Output_Buffer);

    end


    //==================================================================
    // CHECK
    //==================================================================

    task CHECK_DATA;

        input [COEFF_WIDTH-1:0] Actual;
        input [COEFF_WIDTH-1:0] Expected;
        input [8*64-1:0] Name;

        begin

            test_count = test_count + 1;

            if(Actual !== Expected) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] %0s Expected=0x%06H Actual=0x%06H",
                    Name,
                    Expected,
                    Actual
                );

            end

            else begin

                $display(
                    "[PASS] %0s = 0x%06H",
                    Name,
                    Actual
                );

            end

        end

    endtask


    //==================================================================
    // MAIN
    //==================================================================

    initial begin

        test_count  = 0;
        error_count = 0;

        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;

        W_addr_1 = 8'b0;
        W_addr_2 = 8'b0;
        W_addr_3 = 8'b0;
        W_addr_4 = 8'b0;

        W_data_1 = {COEFF_WIDTH{1'b0}};
        W_data_2 = {COEFF_WIDTH{1'b0}};
        W_data_3 = {COEFF_WIDTH{1'b0}};
        W_data_4 = {COEFF_WIDTH{1'b0}};

        R_addr = 8'b0;


        //==============================================================
        // TEST 1:
        // Four simultaneous writes
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: FOUR SIMULTANEOUS WRITES");
        $display("==============================================");


        @(negedge ACLK);

        W_EN_1 = 1'b1;
        W_EN_2 = 1'b1;
        W_EN_3 = 1'b1;
        W_EN_4 = 1'b1;

        W_addr_1 = 8'd0;
        W_addr_2 = 8'd1;
        W_addr_3 = 8'd2;
        W_addr_4 = 8'd3;

        W_data_1 = 23'h100001;
        W_data_2 = 23'h100002;
        W_data_3 = 23'h100003;
        W_data_4 = 23'h100004;


        @(posedge ACLK);

        #1;


        @(negedge ACLK);

        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        //--------------------------------------------------------------
        // Read back 0 ~ 3
        //--------------------------------------------------------------

        R_addr = 8'd0;
        #1;

        CHECK_DATA(
            R_data,
            23'h100001,
            "Buffer[0]"
        );


        R_addr = 8'd1;
        #1;

        CHECK_DATA(
            R_data,
            23'h100002,
            "Buffer[1]"
        );


        R_addr = 8'd2;
        #1;

        CHECK_DATA(
            R_data,
            23'h100003,
            "Buffer[2]"
        );


        R_addr = 8'd3;
        #1;

        CHECK_DATA(
            R_data,
            23'h100004,
            "Buffer[3]"
        );


        //==============================================================
        // TEST 2:
        // Another four writes at arbitrary addresses
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: ARBITRARY ADDRESSES");
        $display("==============================================");


        @(negedge ACLK);

        W_EN_1 = 1'b1;
        W_EN_2 = 1'b1;
        W_EN_3 = 1'b1;
        W_EN_4 = 1'b1;

        W_addr_1 = 8'd64;
        W_addr_2 = 8'd128;
        W_addr_3 = 8'd192;
        W_addr_4 = 8'd255;

        W_data_1 = 23'h200001;
        W_data_2 = 23'h200002;
        W_data_3 = 23'h200003;
        W_data_4 = 23'h200004;


        @(posedge ACLK);

        #1;


        @(negedge ACLK);

        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        R_addr = 8'd64;
        #1;

        CHECK_DATA(
            R_data,
            23'h200001,
            "Buffer[64]"
        );


        R_addr = 8'd128;
        #1;

        CHECK_DATA(
            R_data,
            23'h200002,
            "Buffer[128]"
        );


        R_addr = 8'd192;
        #1;

        CHECK_DATA(
            R_data,
            23'h200003,
            "Buffer[192]"
        );


        R_addr = 8'd255;
        #1;

        CHECK_DATA(
            R_data,
            23'h200004,
            "Buffer[255]"
        );


        //==============================================================
        // TEST 3:
        // Write enable behavior
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: WRITE ENABLE");
        $display("==============================================");


        //--------------------------------------------------------------
        // W_EN_1 remains zero.
        //
        // Therefore Buffer[0] must remain unchanged.
        //--------------------------------------------------------------

        @(negedge ACLK);

        W_addr_1 = 8'd0;
        W_data_1 = 23'h777777;
        W_EN_1   = 1'b0;


        @(posedge ACLK);

        #1;


        R_addr = 8'd0;
        #1;


        CHECK_DATA(
            R_data,
            23'h100001,
            "Disabled write does not modify data"
        );


        //==============================================================
        // SUMMARY
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST SUMMARY");
        $display("==============================================");

        $display(
            "Checks : %0d",
            test_count
        );

        $display(
            "Errors : %0d",
            error_count
        );


        if(error_count == 0) begin

            $display("");
            $display("ALL OUTPUT BUFFER TESTS PASSED");

        end

        else begin

            $display("");
            $display("OUTPUT BUFFER TEST FAILED");

        end


        #20;

        $finish;

    end


endmodule
