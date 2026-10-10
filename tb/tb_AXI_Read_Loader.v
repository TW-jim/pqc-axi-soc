`timescale 1ns / 1ps

module tb_AXI_Read_Loader;


    //==================================================================
    // Configuration
    //==================================================================

    localparam COEFF_WIDTH = 23;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // Loader command
    //==================================================================

    reg        Load_start;
    reg [31:0] Base_addr;


    //==================================================================
    // AXI AR
    //==================================================================

    wire [31:0] M_AXI_ARADDR;
    wire [7:0]  M_AXI_ARLEN;
    wire [2:0]  M_AXI_ARSIZE;
    wire [1:0]  M_AXI_ARBURST;

    wire M_AXI_ARVALID;
    reg  M_AXI_ARREADY;


    //==================================================================
    // AXI R
    //
    // Testbench acts as AXI Memory Slave.
    //==================================================================

    reg [31:0] M_AXI_RDATA;
    reg [1:0]  M_AXI_RRESP;
    reg        M_AXI_RVALID;
    reg        M_AXI_RLAST;

    wire       M_AXI_RREADY;


    //==================================================================
    // Input Buffer Write Interface
    //==================================================================

    wire                       Buffer_W_EN;
    wire [7:0]                 Buffer_W_addr;
    wire [COEFF_WIDTH-1:0]     Buffer_W_data;


    //==================================================================
    // Input Buffer Read Interface
    //
    // Used by TB after load completes to verify stored coefficients.
    //==================================================================

    reg [7:0] Buffer_R_addr_1;
    reg [7:0] Buffer_R_addr_2;
    reg [7:0] Buffer_R_addr_3;
    reg [7:0] Buffer_R_addr_4;

    wire [COEFF_WIDTH-1:0] Buffer_R_data_1;
    wire [COEFF_WIDTH-1:0] Buffer_R_data_2;
    wire [COEFF_WIDTH-1:0] Buffer_R_data_3;
    wire [COEFF_WIDTH-1:0] Buffer_R_data_4;


    //==================================================================
    // Loader status
    //==================================================================

    wire Load_done;
    wire Busy;
    wire Load_error;


    //==================================================================
    // TB statistics
    //==================================================================

    integer test_count;
    integer error_count;

    integer burst;
    integer beat;
    integer global_index;
    integer buffer_write_count;


    //==================================================================
    // DUT: AXI Read Loader
    //==================================================================

    AXI_Read_Loader #(

        .COEFF_WIDTH(COEFF_WIDTH)

    ) DUT (

        .ACLK           (ACLK),
        .ARESETn        (ARESETn),

        .Load_start     (Load_start),
        .Base_addr      (Base_addr),

        // AR
        .M_AXI_ARADDR   (M_AXI_ARADDR),
        .M_AXI_ARLEN    (M_AXI_ARLEN),
        .M_AXI_ARSIZE   (M_AXI_ARSIZE),
        .M_AXI_ARBURST  (M_AXI_ARBURST),
        .M_AXI_ARVALID  (M_AXI_ARVALID),
        .M_AXI_ARREADY  (M_AXI_ARREADY),

        // R
        .M_AXI_RDATA    (M_AXI_RDATA),
        .M_AXI_RRESP    (M_AXI_RRESP),
        .M_AXI_RVALID   (M_AXI_RVALID),
        .M_AXI_RLAST    (M_AXI_RLAST),
        .M_AXI_RREADY   (M_AXI_RREADY),

        // Buffer
        .Buffer_W_EN    (Buffer_W_EN),
        .Buffer_W_addr  (Buffer_W_addr),
        .Buffer_W_data  (Buffer_W_data),

        // Status
        .Load_done      (Load_done),
        .Busy           (Busy),
        .Load_error     (Load_error)
    );


    //==================================================================
    // Input Buffer
    //==================================================================

    Input_Buffer #(

        .COEFF_WIDTH(COEFF_WIDTH),
        .DEPTH(256),
        .ADDR_WIDTH(8)

    ) u_Input_Buffer (

        .ACLK       (ACLK),

        .W_EN       (Buffer_W_EN),
        .W_addr     (Buffer_W_addr),
        .W_data     (Buffer_W_data),

        .R_addr_1   (Buffer_R_addr_1),
        .R_addr_2   (Buffer_R_addr_2),
        .R_addr_3   (Buffer_R_addr_3),
        .R_addr_4   (Buffer_R_addr_4),

        .R_data_1   (Buffer_R_data_1),
        .R_data_2   (Buffer_R_data_2),
        .R_data_3   (Buffer_R_data_3),
        .R_data_4   (Buffer_R_data_4)
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

        $dumpfile("AXI_Read_Loader_tb.vcd");
        $dumpvars(0, tb_AXI_Read_Loader);

    end


    //==================================================================
    // Count actual Input_Buffer writes
    //==================================================================

    always @(posedge ACLK or negedge ARESETn) begin

        if(!ARESETn) begin

            buffer_write_count <= 0;

        end

        else begin

            if(Buffer_W_EN) begin

                buffer_write_count <=
                    buffer_write_count + 1;

            end

        end

    end


    //==================================================================
    // CHECK helpers
    //==================================================================

    task CHECK_1;

        input Actual;
        input Expected;
        input [8*64-1:0] Name;

        begin

            test_count = test_count + 1;

            if(Actual !== Expected) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] %0s Expected=%b Actual=%b",
                    Name,
                    Expected,
                    Actual
                );

            end
            else begin

                $display(
                    "[PASS] %0s",
                    Name
                );

            end

        end

    endtask


    task CHECK_32;

        input [31:0] Actual;
        input [31:0] Expected;
        input [8*64-1:0] Name;

        begin

            test_count = test_count + 1;

            if(Actual !== Expected) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] %0s Expected=0x%08H Actual=0x%08H",
                    Name,
                    Expected,
                    Actual
                );

            end
            else begin

                $display(
                    "[PASS] %0s = 0x%08H",
                    Name,
                    Actual
                );

            end

        end

    endtask


    //==================================================================
    // SEND_ONE_R_BEAT
    //
    // Testbench behaves like AXI Memory Slave.
    //==================================================================

    task automatic SEND_ONE_R_BEAT;

        input [31:0] Data;
        input        Last;

        begin

            //----------------------------------------------------------
            // Present data before rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_RDATA  = Data;
            M_AXI_RRESP  = 2'b00;
            M_AXI_RLAST  = Last;
            M_AXI_RVALID = 1'b1;


            //----------------------------------------------------------
            // Wait until Master is ready.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(M_AXI_RREADY !== 1'b1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // R handshake occurred at previous rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_RVALID = 1'b0;
            M_AXI_RLAST  = 1'b0;

        end

    endtask


    //==================================================================
    // MAIN
    //==================================================================

    initial begin

        test_count = 0;
        error_count = 0;

        ARESETn = 1'b0;

        Load_start = 1'b0;
        Base_addr  = 32'b0;

        M_AXI_ARREADY = 1'b0;

        M_AXI_RDATA  = 32'b0;
        M_AXI_RRESP  = 2'b00;
        M_AXI_RVALID = 1'b0;
        M_AXI_RLAST  = 1'b0;

        Buffer_R_addr_1 = 8'd0;
        Buffer_R_addr_2 = 8'd0;
        Buffer_R_addr_3 = 8'd0;
        Buffer_R_addr_4 = 8'd0;


        //==============================================================
        // RESET
        //==============================================================

        repeat(2)
            @(posedge ACLK);

        @(negedge ACLK);

        ARESETn = 1'b1;

        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Reset Busy"
        );

        CHECK_1(
            Load_done,
            1'b0,
            "Reset Load_done"
        );

        CHECK_1(
            Load_error,
            1'b0,
            "Reset Load_error"
        );


        //==============================================================
        // START
        //==============================================================

        @(negedge ACLK);

        Base_addr  = 32'h1000_1000;
        Load_start = 1'b1;


        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b1,
            "Loader Busy after Start"
        );


        @(negedge ACLK);

        Load_start = 1'b0;


        //==============================================================
        // SEND 16 AXI BURSTS
        //==============================================================

        global_index = 0;


        for(burst = 0; burst < 16; burst = burst + 1) begin


            //----------------------------------------------------------
            // Wait until loader presents an AR request.
            //----------------------------------------------------------

            wait(M_AXI_ARVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Check burst address.
            //----------------------------------------------------------

            CHECK_32(
                M_AXI_ARADDR,
                32'h1000_1000 + (burst * 64),
                "ARADDR"
            );


            //----------------------------------------------------------
            // Check burst attributes.
            //----------------------------------------------------------

            if(M_AXI_ARLEN !== 8'd15) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] ARLEN should be 15"
                );

            end


            if(M_AXI_ARSIZE !== 3'b010) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] ARSIZE should be 2"
                );

            end


            if(M_AXI_ARBURST !== 2'b01) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] ARBURST should be INCR"
                );

            end


            //----------------------------------------------------------
            // Introduce some AR backpressure.
            //
            // Memory intentionally waits one cycle before accepting AR.
            //----------------------------------------------------------

            @(posedge ACLK);

            @(negedge ACLK);

            M_AXI_ARREADY = 1'b1;


            @(posedge ACLK);

            #1;


            //----------------------------------------------------------
            // After AR handshake, ARVALID should clear.
            //----------------------------------------------------------

            CHECK_1(
                M_AXI_ARVALID,
                1'b0,
                "ARVALID clears after handshake"
            );


            @(negedge ACLK);

            M_AXI_ARREADY = 1'b0;


            //----------------------------------------------------------
            // Send 16 read data beats.
            //----------------------------------------------------------

            for(beat = 0; beat < 16; beat = beat + 1) begin


                //------------------------------------------------------
                // Occasionally insert a gap where RVALID=0.
                //
                // This proves that the loader only writes the buffer
                // when a real RVALID/RREADY handshake occurs.
                //------------------------------------------------------

                if((beat % 5) == 0) begin

                    @(posedge ACLK);

                end


                //------------------------------------------------------
                // Data pattern:
                //
                //      0x00500000 + global coefficient index
                //
                // This fits inside 23 bits.
                //------------------------------------------------------

                SEND_ONE_R_BEAT(

                    32'h0050_0000 + global_index,

                    (beat == 15)

                );


                global_index = global_index + 1;

            end

        end


        //==============================================================
        // FINAL COMPLETION
        //==============================================================

        // Final R handshake just occurred.
        //
        // Give sequential outputs time to settle.
        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Busy clears after coefficient 255"
        );


        CHECK_1(
            Load_done,
            1'b1,
            "Load_done asserted after final beat"
        );


        CHECK_1(
            Load_error,
            1'b0,
            "No AXI load error"
        );


        //--------------------------------------------------------------
        // Exactly 256 coefficients must have been written.
        //--------------------------------------------------------------

        if(buffer_write_count !== 256) begin

            error_count = error_count + 1;

            $display(
                "[FAIL] Expected 256 buffer writes, actual=%0d",
                buffer_write_count
            );

        end
        else begin

            $display(
                "[PASS] Buffer write count = 256"
            );

        end


        //==============================================================
        // VERIFY INPUT BUFFER CONTENT
        //==============================================================

        Buffer_R_addr_1 = 8'd0;
        Buffer_R_addr_2 = 8'd1;
        Buffer_R_addr_3 = 8'd127;
        Buffer_R_addr_4 = 8'd255;

        #1;


        CHECK_32(
            {9'b0, Buffer_R_data_1},
            32'h0050_0000,
            "Buffer coefficient 0"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_2},
            32'h0050_0001,
            "Buffer coefficient 1"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_3},
            32'h0050_007F,
            "Buffer coefficient 127"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_4},
            32'h0050_00FF,
            "Buffer coefficient 255"
        );


        //==============================================================
        // Load_done must be a pulse
        //==============================================================

        @(posedge ACLK);

        #1;


        CHECK_1(
            Load_done,
            1'b0,
            "Load_done is one-cycle pulse"
        );


        //==============================================================
        // SUMMARY
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST SUMMARY");
        $display("==============================================");

        $display("Checks : %0d", test_count);
        $display("Errors : %0d", error_count);


        if(error_count == 0) begin

            $display("");
            $display("ALL AXI READ LOADER TESTS PASSED");

        end
        else begin

            $display("");
            $display("AXI READ LOADER TEST FAILED");

        end


        #20;

        $finish;

    end

endmodule
