`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: NTT_AXIL_Regs_tb
//
// Purpose:
//   Verify the AXI4-Lite WRITE path of NTT_AXIL_Regs.
//
//   In this testbench:
//
//       Testbench = AXI Master
//       DUT       = AXI Slave
//
//   We will verify:
//
//       1. Reset
//       2. AW and W arrive together
//       3. AW arrives before W
//       4. W arrives before AW
//       5. WSTRB partial write
//       6. B channel backpressure
//       7. CONTROL register / Start_pulse / Mode
//
//----------------------------------------------------------------------
// AXI4-Lite WRITE transaction:
//
//              AXI Master                    AXI Slave
//              Testbench                   NTT_AXIL_Regs
//
// AW Channel:
//
//     AWADDR   -------------------------------->
//     AWVALID  -------------------------------->
//     AWREADY  <--------------------------------
//
// W Channel:
//
//     WDATA    -------------------------------->
//     WSTRB    -------------------------------->
//     WVALID   -------------------------------->
//     WREADY   <--------------------------------
//
// B Channel:
//
//     BRESP    <--------------------------------
//     BVALID   <--------------------------------
//     BREADY   -------------------------------->
//
// IMPORTANT:
//
//   AW and W are INDEPENDENT channels.
//
//   Therefore:
//
//       AW can arrive first.
//       W can arrive first.
//       AW and W can arrive together.
//
//======================================================================

module tb_NTT_AXIL_Regs;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // AXI4-Lite AW Channel
    //
    // Testbench is Master:
    //
    //   AWADDR, AWVALID -> driven by TB
    //   AWREADY          -> driven by DUT
    //==================================================================

    reg  [31:0] S_AXI_AWADDR;
    reg         S_AXI_AWVALID;
    wire        S_AXI_AWREADY;


    //==================================================================
    // AXI4-Lite W Channel
    //
    // Testbench is Master:
    //
    //   WDATA, WSTRB, WVALID -> driven by TB
    //   WREADY               -> driven by DUT
    //==================================================================

    reg  [31:0] S_AXI_WDATA;
    reg  [3:0]  S_AXI_WSTRB;
    reg         S_AXI_WVALID;
    wire        S_AXI_WREADY;


    //==================================================================
    // AXI4-Lite B Channel
    //
    // DUT is Slave:
    //
    //   BRESP, BVALID -> driven by DUT
    //   BREADY        -> driven by TB
    //==================================================================

    wire [1:0] S_AXI_BRESP;
    wire       S_AXI_BVALID;
    reg        S_AXI_BREADY;


    //==================================================================
    // DUT Control Outputs
    //==================================================================

    wire        Start_pulse;
    wire        Mode;
    wire [31:0] Src_addr;
    wire [31:0] Dst_addr;


    //==================================================================
    // Test statistics
    //==================================================================

    integer test_count;
    integer error_count;


    //==================================================================
    // DUT Instance
    //==================================================================

    NTT_AXIL_Regs DUT (

        .ACLK           (ACLK),
        .ARESETn        (ARESETn),

        // AW
        .S_AXI_AWADDR   (S_AXI_AWADDR),
        .S_AXI_AWVALID  (S_AXI_AWVALID),
        .S_AXI_AWREADY  (S_AXI_AWREADY),

        // W
        .S_AXI_WDATA    (S_AXI_WDATA),
        .S_AXI_WSTRB    (S_AXI_WSTRB),
        .S_AXI_WVALID   (S_AXI_WVALID),
        .S_AXI_WREADY   (S_AXI_WREADY),

        // B
        .S_AXI_BRESP    (S_AXI_BRESP),
        .S_AXI_BVALID   (S_AXI_BVALID),
        .S_AXI_BREADY   (S_AXI_BREADY),

        // Control outputs
        .Start_pulse    (Start_pulse),
        .Mode           (Mode),
        .Src_addr       (Src_addr),
        .Dst_addr       (Dst_addr)
    );


    //==================================================================
    // Clock Generation
    //
    // Clock period = 10 ns
    //
    // Frequency:
    //
    //      1 / 10 ns = 100 MHz
    //
    //==================================================================

    initial begin

        ACLK = 1'b0;

        forever begin
            #5 ACLK = ~ACLK;
        end

    end


    //==================================================================
    // Waveform Dump
    //
    // With Verilator --trace, this generates:
    //
    //      NTT_AXIL_Regs_tb.vcd
    //
    // Later we can open this using GTKWave.
    //==================================================================

    initial begin

        $dumpfile("NTT_AXIL_Regs_tb.vcd");

        // Dump all signals below this testbench.
        $dumpvars(0, NTT_AXIL_Regs_tb);

    end


    //==================================================================
    // CHECK_32 Task
    //
    // Self-checking helper.
    //
    // Instead of only looking at waveform manually,
    // the TB automatically compares:
    //
    //      Actual vs Expected
    //
    //==================================================================

    task CHECK_32;

        input [31:0] Actual;
        input [31:0] Expected;
        input [8*64-1:0] Name;

        begin

            test_count = test_count + 1;

            if(Actual !== Expected) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] %0s : Expected = 0x%08H, Actual = 0x%08H",
                    Name,
                    Expected,
                    Actual
                );

            end
            else begin

                $display(
                    "[PASS] %0s : 0x%08H",
                    Name,
                    Actual
                );

            end

        end

    endtask


    //==================================================================
    // CHECK_1 Task
    //
    // Same idea as CHECK_32, but for 1-bit signals.
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
                    "[FAIL] %0s : Expected = %b, Actual = %b",
                    Name,
                    Expected,
                    Actual
                );

            end
            else begin

                $display(
                    "[PASS] %0s : %b",
                    Name,
                    Actual
                );

            end

        end

    endtask


    //==================================================================
    // RESET_DUT
    //==================================================================
    //
    // DUT reset:
    //
    //      ARESETn = 0 -> Reset
    //      ARESETn = 1 -> Normal
    //
    // Why do we release reset at negedge?
    //
    //   It avoids changing ARESETn at exactly the same instant as the
    //   positive edge where DUT sequential logic is evaluated.
    //
    //==================================================================

    task RESET_DUT;

        begin

            //----------------------------------------------------------
            // Put AXI Master signals into idle state.
            //----------------------------------------------------------

            S_AXI_AWADDR  = 32'b0;
            S_AXI_AWVALID = 1'b0;

            S_AXI_WDATA   = 32'b0;
            S_AXI_WSTRB   = 4'b0;
            S_AXI_WVALID  = 1'b0;

            S_AXI_BREADY  = 1'b0;


            //----------------------------------------------------------
            // Assert reset.
            //----------------------------------------------------------

            ARESETn = 1'b0;


            //----------------------------------------------------------
            // Keep reset active for two clock cycles.
            //----------------------------------------------------------

            repeat(2)
                @(posedge ACLK);


            //----------------------------------------------------------
            // Release reset at falling edge.
            //
            // This gives ARESETn half a clock cycle to become stable
            // before the next positive edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            ARESETn = 1'b1;


            //----------------------------------------------------------
            // Wait one normal operating cycle.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;

        end

    endtask


    //==================================================================
    // SEND_AW
    //==================================================================
    //
    // This task performs ONLY the AXI Write Address channel.
    //
    // Parameters:
    //
    //   Address
    //
    //       Address to send.
    //
    //   Delay_cycles
    //
    //       Number of cycles to wait before asserting AWVALID.
    //
    // This allows us to intentionally create:
    //
    //       AW before W
    //
    // or:
    //
    //       W before AW
    //
    //==================================================================

    task automatic SEND_AW;

        input [31:0] Address;
        input integer Delay_cycles;

        integer i;

        begin

            //----------------------------------------------------------
            // Optional delay.
            //----------------------------------------------------------

            for(i = 0; i < Delay_cycles; i = i + 1) begin
                @(posedge ACLK);
            end


            //----------------------------------------------------------
            // Drive AXI signals on falling edge.
            //
            // Therefore they are stable before the next rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_AWADDR  = Address;
            S_AXI_AWVALID = 1'b1;


            //----------------------------------------------------------
            // AXI Handshake rule:
            //
            //      AWVALID && AWREADY
            //
            // must both be 1 at rising edge.
            //
            // Master MUST keep AWVALID asserted while waiting for
            // AWREADY.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(S_AXI_AWREADY !== 1'b1) begin

                @(posedge ACLK);

            end


            //----------------------------------------------------------
            // At the previous rising edge:
            //
            //      AWVALID = 1
            //      AWREADY = 1
            //
            // therefore address handshake completed.
            //
            // Deassert AWVALID on falling edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_AWVALID = 1'b0;

        end

    endtask


    //==================================================================
    // SEND_W
    //==================================================================
    //
    // Performs ONLY AXI Write Data channel.
    //
    // Remember:
    //
    //      AW and W are independent.
    //
    // This task knows nothing about AW.
    //
    //==================================================================

    task automatic SEND_W;

        input [31:0] Data;
        input [3:0]  Wstrb;
        input integer Delay_cycles;

        integer i;

        begin

            //----------------------------------------------------------
            // Optional delay.
            //----------------------------------------------------------

            for(i = 0; i < Delay_cycles; i = i + 1) begin
                @(posedge ACLK);
            end


            //----------------------------------------------------------
            // Present WDATA before positive edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_WDATA  = Data;
            S_AXI_WSTRB  = Wstrb;
            S_AXI_WVALID = 1'b1;


            //----------------------------------------------------------
            // Wait for:
            //
            //      WVALID && WREADY
            //
            // handshake.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(S_AXI_WREADY !== 1'b1) begin

                @(posedge ACLK);

            end


            //----------------------------------------------------------
            // W handshake completed.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_WVALID = 1'b0;

        end

    endtask


    //==================================================================
    // WAIT_BVALID
    //==================================================================
    //
    // After AW and W are both accepted, DUT eventually performs:
    //
    //      register write
    //
    // then:
    //
    //      BVALID = 1
    //
    // This task waits for that response.
    //==================================================================

    task automatic WAIT_BVALID;

        begin

            //----------------------------------------------------------
            // wait() will stop here until BVALID becomes exactly 1.
            //----------------------------------------------------------

            wait(S_AXI_BVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Our first DUT version always returns:
            //
            //      BRESP = 2'b00
            //
            // AXI meaning:
            //
            //      OKAY
            //----------------------------------------------------------

            if(S_AXI_BRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] BRESP should be AXI OKAY, BRESP = %b",
                    S_AXI_BRESP
                );

            end

        end

    endtask


    //==================================================================
    // ACCEPT_B
    //==================================================================
    //
    // Master accepts the AXI write response.
    //
    // Stall_cycles allows us to intentionally keep:
    //
    //      BREADY = 0
    //
    // while:
    //
    //      BVALID = 1
    //
    // This creates AXI backpressure.
    //
    // AXI rule:
    //
    //      Once BVALID is asserted,
    //      it must stay asserted until BREADY handshake.
    //
    //==================================================================

    task automatic ACCEPT_B;

        input integer Stall_cycles;

        integer i;

        begin

            //----------------------------------------------------------
            // Make sure response already exists.
            //----------------------------------------------------------

            wait(S_AXI_BVALID === 1'b1);


            //----------------------------------------------------------
            // Keep BREADY low intentionally.
            //----------------------------------------------------------

            S_AXI_BREADY = 1'b0;


            //----------------------------------------------------------
            // During backpressure, BVALID must NOT disappear.
            //----------------------------------------------------------

            for(i = 0; i < Stall_cycles; i = i + 1) begin

                @(posedge ACLK);

                #1;

                if(S_AXI_BVALID !== 1'b1) begin

                    error_count = error_count + 1;

                    $display(
                        "[FAIL] BVALID dropped while BREADY = 0"
                    );

                end

            end


            //----------------------------------------------------------
            // Master becomes ready.
            //
            // Drive BREADY at falling edge so it is stable before
            // next rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_BREADY = 1'b1;


            //----------------------------------------------------------
            // At this rising edge:
            //
            //      BVALID = 1
            //      BREADY = 1
            //
            // => B-channel handshake.
            //----------------------------------------------------------

            @(posedge ACLK);


            //----------------------------------------------------------
            // Wait until sequential logic has updated.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_BREADY = 1'b0;


            //----------------------------------------------------------
            // BVALID should now be cleared by DUT.
            //----------------------------------------------------------

            if(S_AXI_BVALID !== 1'b0) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] BVALID did not clear after B handshake"
                );

            end

        end

    endtask


    //==================================================================
    // AXI_WRITE
    //==================================================================
    //
    // Complete AXI4-Lite write transaction.
    //
    // AW and W run IN PARALLEL using fork...join.
    //
    // This is very important.
    //
    // Wrong idea:
    //
    //      SEND_AW();
    //      SEND_W();
    //
    // That would artificially force AW to complete before W.
    //
    // AXI does NOT require that.
    //
    // Therefore:
    //
    //      fork
    //          SEND_AW
    //          SEND_W
    //      join
    //
    // allows both channels to operate independently.
    //
    //==================================================================

    task automatic AXI_WRITE;

        input [31:0] Address;
        input [31:0] Data;
        input [3:0]  Wstrb;

        input integer AW_delay;
        input integer W_delay;
        input integer B_stall;

        begin

            //----------------------------------------------------------
            // AW and W channels run simultaneously.
            //----------------------------------------------------------

            fork

                SEND_AW(
                    Address,
                    AW_delay
                );

                SEND_W(
                    Data,
                    Wstrb,
                    W_delay
                );

            join


            //----------------------------------------------------------
            // AW and W have both completed.
            //
            // DUT should now eventually generate BVALID.
            //----------------------------------------------------------

            WAIT_BVALID();


            //----------------------------------------------------------
            // Accept B response.
            //----------------------------------------------------------

            ACCEPT_B(
                B_stall
            );

        end

    endtask


    //==================================================================
    // MAIN TEST SEQUENCE
    //==================================================================

    initial begin


        //==============================================================
        // Initialization
        //==============================================================

        test_count  = 0;
        error_count = 0;

        ARESETn = 1'b0;

        S_AXI_AWADDR  = 32'b0;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA   = 32'b0;
        S_AXI_WSTRB   = 4'b0;
        S_AXI_WVALID  = 1'b0;

        S_AXI_BREADY  = 1'b0;


        //==============================================================
        // TEST 1
        // RESET
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 1: RESET");
        $display("================================================");

        RESET_DUT();

        CHECK_1(
            Start_pulse,
            1'b0,
            "Reset Start_pulse"
        );

        CHECK_1(
            Mode,
            1'b0,
            "Reset Mode"
        );

        CHECK_32(
            Src_addr,
            32'h0000_0000,
            "Reset Src_addr"
        );

        CHECK_32(
            Dst_addr,
            32'h0000_0000,
            "Reset Dst_addr"
        );

        CHECK_1(
            S_AXI_BVALID,
            1'b0,
            "Reset BVALID"
        );


        //==============================================================
        // TEST 2
        // AW and W arrive at the same time
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 2: BASIC AXI WRITE");
        $display("AW and W arrive together");
        $display("================================================");

        //--------------------------------------------------------------
        // Write:
        //
        //      SRC_ADDR = 0x12345678
        //
        // Address offset:
        //
        //      0x08
        //
        // WSTRB:
        //
        //      1111 = all four bytes enabled
        //
        // AW_delay = 0
        // W_delay  = 0
        //
        // Therefore AW and W begin together.
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_0008,
            32'h1234_5678,
            4'b1111,
            0,
            0,
            0
        );

        CHECK_32(
            Src_addr,
            32'h1234_5678,
            "Basic SRC_ADDR write"
        );


        //==============================================================
        // TEST 3
        // AW arrives BEFORE W
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 3: AW BEFORE W");
        $display("================================================");

        //--------------------------------------------------------------
        // AW immediately.
        //
        // W waits three clock cycles.
        //
        // Expected behavior:
        //
        //      DUT stores AWADDR in awaddr_reg.
        //
        //      awaddr_pending = 1
        //
        //      DUT waits for WDATA.
        //
        // This directly tests whether AW and W are truly independent.
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_000C,
            32'hCAFE_BABE,
            4'b1111,
            0,              // AW delay
            3,              // W delay
            0               // B stall
        );

        CHECK_32(
            Dst_addr,
            32'hCAFE_BABE,
            "AW before W"
        );


        //==============================================================
        // TEST 4
        // W arrives BEFORE AW
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 4: W BEFORE AW");
        $display("================================================");

        //--------------------------------------------------------------
        // Reverse TEST 3.
        //
        // WDATA arrives immediately.
        //
        // AWADDR arrives three clocks later.
        //
        // Expected:
        //
        //      DUT stores:
        //
        //          wdata_reg
        //          wstrb_reg
        //
        //      and waits for AWADDR.
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_0008,
            32'hDEAD_BEEF,
            4'b1111,
            3,              // AW delay
            0,              // W delay
            0
        );

        CHECK_32(
            Src_addr,
            32'hDEAD_BEEF,
            "W before AW"
        );


        //==============================================================
        // TEST 5
        // WSTRB partial write
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 5: WSTRB PARTIAL WRITE");
        $display("================================================");

        //--------------------------------------------------------------
        // First initialize:
        //
        //      SRC_ADDR = 0x11223344
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_0008,
            32'h1122_3344,
            4'b1111,
            0,
            0,
            0
        );

        CHECK_32(
            Src_addr,
            32'h1122_3344,
            "WSTRB initial value"
        );


        //--------------------------------------------------------------
        // Second write:
        //
        //      WDATA = AABBCCDD
        //
        //      WSTRB = 0010
        //
        // Only WSTRB[1] is enabled.
        //
        // Therefore only:
        //
        //      bits [15:8]
        //
        // are replaced.
        //
        //
        // Initial:
        //
        //      11 22 33 44
        //
        // New:
        //
        //      AA BB CC DD
        //
        // Strobe:
        //
        //       0  0  1  0
        //
        // Result:
        //
        //      11 22 CC 44
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_0008,
            32'hAABB_CCDD,
            4'b0010,
            0,
            0,
            0
        );

        CHECK_32(
            Src_addr,
            32'h1122_CC44,
            "WSTRB byte enable"
        );


        //==============================================================
        // TEST 6
        // BREADY Backpressure
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 6: BREADY BACKPRESSURE");
        $display("================================================");

        //--------------------------------------------------------------
        // B_stall = 3
        //
        // After DUT asserts:
        //
        //      BVALID = 1
        //
        // Master intentionally holds:
        //
        //      BREADY = 0
        //
        // for three cycles.
        //
        // AXI requires BVALID to remain HIGH.
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_000C,
            32'h5566_7788,
            4'b1111,
            0,
            0,
            3               // BREADY stall
        );

        CHECK_32(
            Dst_addr,
            32'h5566_7788,
            "BREADY backpressure write"
        );


        //==============================================================
        // TEST 7
        // CONTROL Register
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 7: CONTROL / START / MODE");
        $display("================================================");


        //--------------------------------------------------------------
        // We do NOT use AXI_WRITE here.
        //
        // Why?
        //
        // Because AXI_WRITE waits until the whole B transaction
        // completes.
        //
        // But Start_pulse is only HIGH for one clock.
        //
        // Therefore we want to inspect Start_pulse exactly when
        // the DUT generates BVALID.
        //--------------------------------------------------------------

        fork

            SEND_AW(
                32'h0000_0000,
                0
            );

            //----------------------------------------------------------
            // WDATA = 3:
            //
            //      bit 1 = MODE  = 1
            //      bit 0 = START = 1
            //----------------------------------------------------------

            SEND_W(
                32'h0000_0003,
                4'b1111,
                0
            );

        join


        //--------------------------------------------------------------
        // Wait until the DUT executes CONTROL write.
        //
        // In our DUT:
        //
        //      Start_pulse <= 1
        //      Mode        <= 1
        //      BVALID      <= 1
        //
        // occur during the same register-write event.
        //--------------------------------------------------------------

        WAIT_BVALID();


        CHECK_1(
            Start_pulse,
            1'b1,
            "CONTROL START pulse asserted"
        );

        CHECK_1(
            Mode,
            1'b1,
            "CONTROL MODE set"
        );


        //--------------------------------------------------------------
        // Start_pulse should last only ONE clock cycle.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;

        CHECK_1(
            Start_pulse,
            1'b0,
            "START pulse returns low"
        );


        //--------------------------------------------------------------
        // Mode is a stored register.
        //
        // Unlike Start_pulse, Mode should stay HIGH.
        //--------------------------------------------------------------

        CHECK_1(
            Mode,
            1'b1,
            "MODE remains stored"
        );


        //--------------------------------------------------------------
        // Finally accept B response.
        //--------------------------------------------------------------

        ACCEPT_B(
            0
        );


        //==============================================================
        // TEST 8
        // CONTROL WSTRB
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 8: CONTROL WSTRB");
        $display("================================================");

        //--------------------------------------------------------------
        // MODE currently = 1.
        //
        // Try writing:
        //
        //      CONTROL data = 0
        //
        // but:
        //
        //      WSTRB = 1110
        //
        // WSTRB[0] = 0.
        //
        // START and MODE live inside byte 0.
        //
        // Therefore CONTROL must NOT change.
        //--------------------------------------------------------------

        AXI_WRITE(
            32'h0000_0000,
            32'h0000_0000,
            4'b1110,
            0,
            0,
            0
        );

        CHECK_1(
            Mode,
            1'b1,
            "CONTROL ignored when WSTRB[0] = 0"
        );


        //==============================================================
        // FINAL RESULT
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST SUMMARY");
        $display("================================================");

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
            $display("========================================");
            $display("ALL AXI4-LITE WRITE TESTS PASSED");
            $display("========================================");

        end
        else begin

            $display("");
            $display("========================================");
            $display("AXI4-LITE WRITE TEST FAILED");
            $display("========================================");

        end


        //--------------------------------------------------------------
        // Allow waveform to continue slightly before stopping.
        //--------------------------------------------------------------

        #20;

        $finish;

    end


endmodule
