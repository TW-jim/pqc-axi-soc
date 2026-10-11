`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: tb_AXI_Write_Writer
//
// Purpose:
//
//   Verify:
//
//       Output_Buffer
//             +
//       AXI_Write_Writer
//
//   together.
//
//----------------------------------------------------------------------
// Testbench roles:
//
//   1. Fill Output_Buffer with 256 known coefficients.
//
//   2. Start AXI_Write_Writer.
//
//   3. Testbench behaves like an AXI4 memory slave:
//
//          - accepts AW requests
//          - accepts W beats
//          - returns B responses
//
//   4. Verify:
//
//          - 16 bursts
//          - 16 beats / burst
//          - 256 coefficients total
//          - AW address sequence
//          - AW backpressure
//          - W backpressure
//          - WDATA stability
//          - WLAST position
//          - WSTRB
//          - B response handling
//          - Write_done
//
//======================================================================

module tb_AXI_Write_Writer;


    //==================================================================
    // Configuration
    //==================================================================

    localparam COEFF_WIDTH = 23;

    // Base coefficient pattern stored in Output_Buffer:
    //
    // buffer[i] = 0x300000 + i
    //
    localparam [COEFF_WIDTH - 1 : 0] DATA_BASE =
        23'h300000;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // Writer Command
    //==================================================================

    reg        Write_start;
    reg [31:0] Base_addr;


    //==================================================================
    // AXI4 Write Address Channel
    //
    // DUT = AXI Master
    // TB  = AXI Slave
    //==================================================================

    wire [31:0] M_AXI_AWADDR;
    wire [7:0]  M_AXI_AWLEN;
    wire [2:0]  M_AXI_AWSIZE;
    wire [1:0]  M_AXI_AWBURST;

    wire M_AXI_AWVALID;
    reg  M_AXI_AWREADY;


    //==================================================================
    // AXI4 Write Data Channel
    //==================================================================

    wire [31:0] M_AXI_WDATA;
    wire [3:0]  M_AXI_WSTRB;

    wire M_AXI_WLAST;
    wire M_AXI_WVALID;

    reg  M_AXI_WREADY;


    //==================================================================
    // AXI4 Write Response Channel
    //==================================================================

    reg [1:0] M_AXI_BRESP;
    reg       M_AXI_BVALID;

    wire      M_AXI_BREADY;


    //==================================================================
    // Output Buffer -> AXI Writer
    //==================================================================

    wire [7:0] Buffer_R_addr;

    wire [COEFF_WIDTH - 1 : 0]
        Buffer_R_data;


    //==================================================================
    // Testbench -> Output Buffer write ports
    //
    // Before starting AXI writeback, TB uses these four ports to
    // initialize all 256 coefficients.
    //==================================================================

    reg W_EN_1;
    reg W_EN_2;
    reg W_EN_3;
    reg W_EN_4;

    reg [7:0] W_addr_1;
    reg [7:0] W_addr_2;
    reg [7:0] W_addr_3;
    reg [7:0] W_addr_4;

    reg [COEFF_WIDTH - 1 : 0] W_data_1;
    reg [COEFF_WIDTH - 1 : 0] W_data_2;
    reg [COEFF_WIDTH - 1 : 0] W_data_3;
    reg [COEFF_WIDTH - 1 : 0] W_data_4;


    //==================================================================
    // Writer Status
    //==================================================================

    wire Write_done;
    wire Busy;
    wire Write_error;


    //==================================================================
    // Testbench Variables
    //==================================================================

    integer test_count;
    integer error_count;

    integer burst;
    integer beat;

    integer accepted_write_count;


    // Used when filling Output_Buffer.
    reg [7:0] fill_addr;


    // Expected AXI values.
    reg [31:0] expected_awaddr;
    reg [31:0] expected_wdata;

    // Coefficient currently expected on AXI W.
    reg [7:0] expected_index;


    //==================================================================
    // MAKE_COEFF
    //
    // Generate the known coefficient pattern:
    //
    //      coefficient[i] = 0x300000 + i
    //
    // Why use a function?
    //
    // fill_addr / expected_index are 8-bit values while the
    // coefficient is 23 bits.
    //
    // Explicit zero extension prevents Verilator WIDTH warnings:
    //
    //      8-bit index
    //          ↓
    //      zero extend to 23 bits
    //          ↓
    //      DATA_BASE + index
    //
    //==================================================================

    function [COEFF_WIDTH - 1 : 0] MAKE_COEFF;

        input [7:0] Index;

        reg [COEFF_WIDTH - 1 : 0] index_extended;

        begin

            index_extended = {
                {(COEFF_WIDTH - 8){1'b0}},
                Index
            };

            MAKE_COEFF =
                DATA_BASE + index_extended;

        end

    endfunction


    //==================================================================
    // DUT: AXI Write Writer
    //==================================================================

    AXI_Write_Writer #(

        .COEFF_WIDTH(COEFF_WIDTH)

    ) DUT (

        //--------------------------------------------------------------
        // Clock / Reset
        //--------------------------------------------------------------

        .ACLK           (ACLK),
        .ARESETn        (ARESETn),


        //--------------------------------------------------------------
        // Command
        //--------------------------------------------------------------

        .Write_start    (Write_start),
        .Base_addr      (Base_addr),


        //--------------------------------------------------------------
        // AXI AW
        //--------------------------------------------------------------

        .M_AXI_AWADDR   (M_AXI_AWADDR),
        .M_AXI_AWLEN    (M_AXI_AWLEN),
        .M_AXI_AWSIZE   (M_AXI_AWSIZE),
        .M_AXI_AWBURST  (M_AXI_AWBURST),

        .M_AXI_AWVALID  (M_AXI_AWVALID),
        .M_AXI_AWREADY  (M_AXI_AWREADY),


        //--------------------------------------------------------------
        // AXI W
        //--------------------------------------------------------------

        .M_AXI_WDATA    (M_AXI_WDATA),
        .M_AXI_WSTRB    (M_AXI_WSTRB),

        .M_AXI_WLAST    (M_AXI_WLAST),
        .M_AXI_WVALID   (M_AXI_WVALID),
        .M_AXI_WREADY   (M_AXI_WREADY),


        //--------------------------------------------------------------
        // AXI B
        //--------------------------------------------------------------

        .M_AXI_BRESP    (M_AXI_BRESP),
        .M_AXI_BVALID   (M_AXI_BVALID),
        .M_AXI_BREADY   (M_AXI_BREADY),


        //--------------------------------------------------------------
        // Output Buffer
        //--------------------------------------------------------------

        .Buffer_R_addr  (Buffer_R_addr),
        .Buffer_R_data  (Buffer_R_data),


        //--------------------------------------------------------------
        // Status
        //--------------------------------------------------------------

        .Write_done     (Write_done),
        .Busy           (Busy),
        .Write_error    (Write_error)

    );


    //==================================================================
    // Output Buffer
    //==================================================================

    Output_Buffer #(

        .COEFF_WIDTH(COEFF_WIDTH),
        .DEPTH(256),
        .ADDR_WIDTH(8)

    ) u_Output_Buffer (

        .ACLK       (ACLK),


        //--------------------------------------------------------------
        // Four write ports
        //--------------------------------------------------------------

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


        //--------------------------------------------------------------
        // Single read port
        //--------------------------------------------------------------

        .R_addr     (Buffer_R_addr),
        .R_data     (Buffer_R_data)

    );


    //==================================================================
    // Clock
    //
    // Period = 10 ns
    // Frequency = 100 MHz
    //==================================================================

    initial begin

        ACLK = 1'b0;

        forever begin

            #5 ACLK = ~ACLK;

        end

    end


    //==================================================================
    // Waveform
    //==================================================================

    initial begin

        $dumpfile(
            "AXI_Write_Writer_tb.vcd"
        );

        $dumpvars(
            0,
            tb_AXI_Write_Writer
        );

    end


    //==================================================================
    // Count accepted AXI W beats
    //
    // An AXI W data beat transfers only when:
    //
    //      WVALID && WREADY
    //
    // We expect exactly:
    //
    //      16 bursts
    //      ×
    //      16 beats
    //
    //      = 256 beats
    //==================================================================

    always @(posedge ACLK or negedge ARESETn) begin

        if(!ARESETn) begin

            accepted_write_count <= 0;

        end

        else begin

            if(M_AXI_WVALID && M_AXI_WREADY) begin

                accepted_write_count <=
                    accepted_write_count + 1;

            end

        end

    end


    //==================================================================
    // CHECK_1
    //==================================================================

    task CHECK_1;

        input Actual;
        input Expected;

        input [8*64-1:0] Name;

        begin

            test_count =
                test_count + 1;


            if(Actual !== Expected) begin

                error_count =
                    error_count + 1;


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


    //==================================================================
    // CHECK_32
    //==================================================================

    task CHECK_32;

        input [31:0] Actual;
        input [31:0] Expected;

        input [8*64-1:0] Name;

        begin

            test_count =
                test_count + 1;


            if(Actual !== Expected) begin

                error_count =
                    error_count + 1;


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
    // ACCEPT_AW
    //
    // Testbench acts as AXI memory slave.
    //
    // Stall_cycles:
    //
    //   Number of cycles to intentionally keep AWREADY low.
    //
    // During this stall:
    //
    //      AWVALID must remain high.
    //      AWADDR must remain stable.
    //==================================================================

    task automatic ACCEPT_AW;

        input [31:0] Expected_addr;
        input integer Stall_cycles;

        integer i;

        reg [31:0] held_addr;

        begin


            //----------------------------------------------------------
            // Wait for AXI master to issue AW request.
            //----------------------------------------------------------

            wait(
                M_AXI_AWVALID === 1'b1
            );

            #1;


            held_addr =
                M_AXI_AWADDR;


            //----------------------------------------------------------
            // Verify address.
            //----------------------------------------------------------

            CHECK_32(
                M_AXI_AWADDR,
                Expected_addr,
                "AWADDR"
            );


            //----------------------------------------------------------
            // Verify AWLEN.
            //
            // 15 means:
            //
            //      15 + 1 = 16 beats
            //----------------------------------------------------------

            if(M_AXI_AWLEN !== 8'd15) begin

                error_count =
                    error_count + 1;

                $display(
                    "[FAIL] AWLEN should be 15, actual=%0d",
                    M_AXI_AWLEN
                );

            end


            //----------------------------------------------------------
            // AWSIZE = 2
            //
            // bytes / beat = 2^2 = 4 bytes
            //----------------------------------------------------------

            if(M_AXI_AWSIZE !== 3'b010) begin

                error_count =
                    error_count + 1;

                $display(
                    "[FAIL] AWSIZE should be 010, actual=%b",
                    M_AXI_AWSIZE
                );

            end


            //----------------------------------------------------------
            // AWBURST = 01 = INCR
            //----------------------------------------------------------

            if(M_AXI_AWBURST !== 2'b01) begin

                error_count =
                    error_count + 1;

                $display(
                    "[FAIL] AWBURST should be INCR, actual=%b",
                    M_AXI_AWBURST
                );

            end


            //----------------------------------------------------------
            // Apply AW backpressure.
            //----------------------------------------------------------

            M_AXI_AWREADY = 1'b0;


            for(
                i = 0;
                i < Stall_cycles;
                i = i + 1
            ) begin

                @(posedge ACLK);

                #1;


                //------------------------------------------------------
                // VALID must remain asserted until handshake.
                //------------------------------------------------------

                if(M_AXI_AWVALID !== 1'b1) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] AWVALID dropped during AW stall"
                    );

                end


                //------------------------------------------------------
                // Payload must remain stable while VALID=1 READY=0.
                //------------------------------------------------------

                if(M_AXI_AWADDR !== held_addr) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] AWADDR changed during AW stall"
                    );

                end

            end


            //----------------------------------------------------------
            // Accept AW request.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_AWREADY = 1'b1;


            //----------------------------------------------------------
            // AW handshake occurs at this rising edge.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            CHECK_1(
                M_AXI_AWVALID,
                1'b0,
                "AWVALID clears after handshake"
            );


            @(negedge ACLK);

            M_AXI_AWREADY = 1'b0;

        end

    endtask


    //==================================================================
    // ACCEPT_W
    //
    // Accept exactly one AXI W beat.
    //
    // During WREADY backpressure verify:
    //
    //      WVALID
    //      WDATA
    //      WLAST
    //      Buffer_R_addr
    //
    // all remain stable.
    //==================================================================

    task automatic ACCEPT_W;

        input [31:0] Expected_data;
        input        Expected_last;

        input integer Stall_cycles;


        integer i;


        reg [31:0] held_data;
        reg        held_last;
        reg [7:0]  held_buffer_addr;


        begin


            //----------------------------------------------------------
            // Wait until Writer presents data.
            //----------------------------------------------------------

            wait(
                M_AXI_WVALID === 1'b1
            );

            #1;


            //----------------------------------------------------------
            // Snapshot current payload.
            //----------------------------------------------------------

            held_data =
                M_AXI_WDATA;

            held_last =
                M_AXI_WLAST;

            held_buffer_addr =
                Buffer_R_addr;


            //----------------------------------------------------------
            // Check data.
            //----------------------------------------------------------

            CHECK_32(
                M_AXI_WDATA,
                Expected_data,
                "WDATA"
            );


            //----------------------------------------------------------
            // Check WLAST.
            //----------------------------------------------------------

            CHECK_1(
                M_AXI_WLAST,
                Expected_last,
                "WLAST"
            );


            //----------------------------------------------------------
            // Entire 32-bit memory word is written.
            //----------------------------------------------------------

            if(M_AXI_WSTRB !== 4'b1111) begin

                error_count =
                    error_count + 1;

                $display(
                    "[FAIL] WSTRB should be 1111, actual=%b",
                    M_AXI_WSTRB
                );

            end


            //----------------------------------------------------------
            // Apply W channel backpressure.
            //----------------------------------------------------------

            M_AXI_WREADY = 1'b0;


            for(
                i = 0;
                i < Stall_cycles;
                i = i + 1
            ) begin

                @(posedge ACLK);

                #1;


                //------------------------------------------------------
                // WVALID must remain asserted.
                //------------------------------------------------------

                if(M_AXI_WVALID !== 1'b1) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] WVALID dropped during W stall"
                    );

                end


                //------------------------------------------------------
                // WDATA must remain stable.
                //------------------------------------------------------

                if(M_AXI_WDATA !== held_data) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] WDATA changed during W stall"
                    );

                end


                //------------------------------------------------------
                // WLAST must remain stable.
                //------------------------------------------------------

                if(M_AXI_WLAST !== held_last) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] WLAST changed during W stall"
                    );

                end


                //------------------------------------------------------
                // The buffer address generates WDATA.
                //
                // Therefore it must also stay stable.
                //------------------------------------------------------

                if(Buffer_R_addr !== held_buffer_addr) begin

                    error_count =
                        error_count + 1;

                    $display(
                        "[FAIL] Buffer_R_addr changed during W stall"
                    );

                end

            end


            //----------------------------------------------------------
            // Accept current W beat.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_WREADY = 1'b1;


            //----------------------------------------------------------
            // WVALID && WREADY handshake occurs here.
            //----------------------------------------------------------

            @(posedge ACLK);


            //----------------------------------------------------------
            // Stop accepting before next beat.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_WREADY = 1'b0;

        end

    endtask


    //==================================================================
    // SEND_B
    //
    // Testbench sends one AXI write response.
    //
    // Resp:
    //
    //      00 = OKAY
    //
    // Delay_cycles:
    //
    //      delay before presenting BVALID
    //==================================================================

    task automatic SEND_B;

        input [1:0] Resp;
        input integer Delay_cycles;

        integer i;

        begin


            //----------------------------------------------------------
            // Optional response delay.
            //----------------------------------------------------------

            for(
                i = 0;
                i < Delay_cycles;
                i = i + 1
            ) begin

                @(posedge ACLK);

            end


            //----------------------------------------------------------
            // Present B response before rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_BRESP  = Resp;
            M_AXI_BVALID = 1'b1;


            //----------------------------------------------------------
            // Wait until Writer is ready to accept B.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(M_AXI_BREADY !== 1'b1) begin

                @(posedge ACLK);

            end


            //----------------------------------------------------------
            // B handshake has occurred.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_BVALID = 1'b0;

        end

    endtask


    //==================================================================
    // MAIN TEST
    //==================================================================

    initial begin


        //==============================================================
        // Initialization
        //==============================================================

        test_count  = 0;
        error_count = 0;


        ARESETn = 1'b0;


        //--------------------------------------------------------------
        // Writer command
        //--------------------------------------------------------------

        Write_start = 1'b0;
        Base_addr   = 32'b0;


        //--------------------------------------------------------------
        // AXI slave signals
        //--------------------------------------------------------------

        M_AXI_AWREADY = 1'b0;

        M_AXI_WREADY = 1'b0;

        M_AXI_BRESP  = 2'b00;
        M_AXI_BVALID = 1'b0;


        //--------------------------------------------------------------
        // Output Buffer fill ports
        //--------------------------------------------------------------

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


        //--------------------------------------------------------------
        // TB bookkeeping
        //--------------------------------------------------------------

        fill_addr = 8'd0;

        expected_awaddr =
            32'h2000_0000;

        expected_wdata =
            32'b0;

        expected_index =
            8'd0;


        //==============================================================
        // TEST 1: RESET
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: RESET");
        $display("==============================================");


        repeat(2) begin

            @(posedge ACLK);

        end


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
            Write_done,
            1'b0,
            "Reset Write_done"
        );


        CHECK_1(
            Write_error,
            1'b0,
            "Reset Write_error"
        );


        //==============================================================
        // TEST 2: FILL OUTPUT BUFFER
        //
        // 64 clocks × 4 writes = 256 coefficients
        //
        // Pattern:
        //
        //      mem[i] = 0x300000 + i
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: FILL OUTPUT BUFFER");
        $display("==============================================");


        fill_addr = 8'd0;


        repeat(64) begin


            //----------------------------------------------------------
            // Prepare four different addresses before rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);


            W_EN_1 = 1'b1;
            W_EN_2 = 1'b1;
            W_EN_3 = 1'b1;
            W_EN_4 = 1'b1;


            W_addr_1 =
                fill_addr;

            W_addr_2 =
                fill_addr + 8'd1;

            W_addr_3 =
                fill_addr + 8'd2;

            W_addr_4 =
                fill_addr + 8'd3;


            //----------------------------------------------------------
            // IMPORTANT:
            //
            // MAKE_COEFF() explicitly converts the 8-bit address into
            // a COEFF_WIDTH-bit value before the addition.
            //
            // This removes Verilator WIDTHEXPAND warnings.
            //----------------------------------------------------------

            W_data_1 =
                MAKE_COEFF(
                    fill_addr
                );

            W_data_2 =
                MAKE_COEFF(
                    fill_addr + 8'd1
                );

            W_data_3 =
                MAKE_COEFF(
                    fill_addr + 8'd2
                );

            W_data_4 =
                MAKE_COEFF(
                    fill_addr + 8'd3
                );


            //----------------------------------------------------------
            // All four writes occur on this edge.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            //----------------------------------------------------------
            // Move to next group of four coefficients.
            //----------------------------------------------------------

            fill_addr =
                fill_addr + 8'd4;

        end


        //--------------------------------------------------------------
        // Stop buffer writes.
        //--------------------------------------------------------------

        @(negedge ACLK);


        W_EN_1 = 1'b0;
        W_EN_2 = 1'b0;
        W_EN_3 = 1'b0;
        W_EN_4 = 1'b0;


        //==============================================================
        // TEST 3: START AXI WRITEBACK
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: START AXI WRITEBACK");
        $display("==============================================");


        Base_addr =
            32'h2000_0000;


        Write_start =
            1'b1;


        //--------------------------------------------------------------
        // Writer accepts Write_start here.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b1,
            "Writer Busy after Start"
        );


        //--------------------------------------------------------------
        // Write_start is a one-cycle command.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Write_start =
            1'b0;


        //==============================================================
        // TEST 4: RECEIVE 16 AXI WRITE BURSTS
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 4: AXI WRITE BURSTS");
        $display("==============================================");


        expected_awaddr =
            32'h2000_0000;


        expected_index =
            8'd0;


        for(
            burst = 0;
            burst < 16;
            burst = burst + 1
        ) begin


            //----------------------------------------------------------
            // Verify / accept AW.
            //
            // First burst:
            //
            //      longer AW backpressure
            //
            // Remaining bursts:
            //
            //      one stall cycle
            //----------------------------------------------------------

            if(burst == 0) begin

                ACCEPT_AW(
                    expected_awaddr,
                    3
                );

            end

            else begin

                ACCEPT_AW(
                    expected_awaddr,
                    1
                );

            end


            //----------------------------------------------------------
            // Accept 16 W beats.
            //----------------------------------------------------------

            for(
                beat = 0;
                beat < 16;
                beat = beat + 1
            ) begin


                //------------------------------------------------------
                // Generate exactly the 32-bit word expected from:
                //
                //      Output_Buffer[expected_index]
                //
                // MAKE_COEFF returns 23 bits.
                //
                // We explicitly zero-extend to 32 bits exactly as
                // AXI_Write_Writer does.
                //------------------------------------------------------

                expected_wdata = {
                    {(32 - COEFF_WIDTH){1'b0}},
                    MAKE_COEFF(expected_index)
                };


                //------------------------------------------------------
                // Every fifth beat receives extra WREADY stall.
                //------------------------------------------------------

                if((beat % 5) == 0) begin

                    ACCEPT_W(
                        expected_wdata,
                        (beat == 15),
                        2
                    );

                end

                else begin

                    ACCEPT_W(
                        expected_wdata,
                        (beat == 15),
                        0
                    );

                end


                //------------------------------------------------------
                // Next coefficient.
                //------------------------------------------------------

                expected_index =
                    expected_index + 8'd1;

            end


            //----------------------------------------------------------
            // After final W beat:
            //
            // Writer must WAIT for B.
            //
            // It must NOT issue the next AW yet.
            //----------------------------------------------------------

            repeat(2) begin

                @(posedge ACLK);

                #1;


                CHECK_1(
                    M_AXI_AWVALID,
                    1'b0,
                    "No next AW before B response"
                );

            end


            //----------------------------------------------------------
            // Successful write response.
            //
            // BRESP = 00 = OKAY.
            //----------------------------------------------------------

            SEND_B(
                2'b00,
                0
            );


            //----------------------------------------------------------
            // Next burst:
            //
            // 16 beats × 4 bytes
            // = 64 bytes
            // = 0x40
            //----------------------------------------------------------

            expected_awaddr =
                expected_awaddr +
                32'h0000_0040;

        end


        //==============================================================
        // TEST 5: COMPLETION
        //==============================================================

        $display("");
        $display("==============================================");
        $display("TEST 5: WRITEBACK COMPLETION");
        $display("==============================================");


        //--------------------------------------------------------------
        // Final B handshake has completed.
        //
        // Give combinational outputs a small amount of simulation
        // settling time.
        //--------------------------------------------------------------

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Writer Busy clears after final B"
        );


        CHECK_1(
            Write_done,
            1'b1,
            "Write_done asserted after final B"
        );


        CHECK_1(
            Write_error,
            1'b0,
            "No write error"
        );


        //--------------------------------------------------------------
        // Exactly 256 coefficients must have been accepted on AXI W.
        //--------------------------------------------------------------

        if(accepted_write_count !== 256) begin

            error_count =
                error_count + 1;


            $display(
                "[FAIL] Expected 256 accepted W beats, actual=%0d",
                accepted_write_count
            );

        end

        else begin

            $display(
                "[PASS] Accepted W beats = 256"
            );

        end


        //==============================================================
        // TEST 6: WRITE_DONE IS ONE-CYCLE PULSE
        //==============================================================

        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_done,
            1'b0,
            "Write_done is one-cycle pulse"
        );


        //==============================================================
        // TEST SUMMARY
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
            $display(
                "ALL AXI WRITE WRITER TESTS PASSED"
            );

        end

        else begin

            $display("");
            $display(
                "AXI WRITE WRITER TEST FAILED"
            );

        end


        #20;

        $finish;

    end


endmodule
