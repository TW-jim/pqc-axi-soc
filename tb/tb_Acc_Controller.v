`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: tb_Acc_Controller
//
// Purpose:
//
//   Verify the control flow of Acc_Controller.
//
//   The controller coordinates:
//
//       AXI-Lite command
//             |
//             v
//       input loading
//             |
//             v
//       NTT/INTT core
//             |
//             v
//       output writeback
//
//----------------------------------------------------------------------
// Expected state flow:
//
//       IDLE
//        |
//        | Start_pulse
//        v
//       LOAD_INPUT
//        |
//        | Load_done
//        v
//       PREP_CORE
//        |
//        | one preparation cycle
//        v
//       RUN_CORE
//        |
//        | Core_fin
//        v
//       PREP_WRITE
//        |
//        | one preparation cycle
//        v
//       WRITE_OUTPUT
//        |
//        | Write_done
//        v
//       IDLE
//
//----------------------------------------------------------------------
// Main behaviors to verify:
//
//   1. Reset
//   2. START causes Busy and Load_start
//   3. Configuration is latched at START
//   4. Configuration does not change while accelerator is running
//   5. START while Busy is ignored
//   6. Load_done eventually generates one-cycle Core_start
//   7. Core_fin eventually generates one-cycle Write_start
//   8. Write_done clears Busy and sets Done
//   9. Done stays high until next START
//  10. Next START clears Done and captures new configuration
//
//======================================================================

module tb_Acc_Controller;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // Command inputs from NTT_AXIL_Regs
    //==================================================================

    reg         Start_pulse;
    reg         Mode;
    reg [31:0]  Src_addr;
    reg [31:0]  Dst_addr;


    //==================================================================
    // Input Loader Interface
    //==================================================================

    wire Load_start;
    reg  Load_done;


    //==================================================================
    // NTT Core Interface
    //==================================================================

    wire Core_start;
    reg  Core_fin;


    //==================================================================
    // Output Writer Interface
    //==================================================================

    wire Write_start;
    reg  Write_done;


    //==================================================================
    // Latched configuration
    //==================================================================

    wire        Mode_latched;
    wire [31:0] Src_addr_latched;
    wire [31:0] Dst_addr_latched;


    //==================================================================
    // Status
    //==================================================================

    wire Busy;
    wire Done;
    wire Error;


    //==================================================================
    // Test statistics
    //==================================================================

    integer test_count;
    integer error_count;


    //==================================================================
    // DUT
    //==================================================================

    Acc_Controller DUT (

        .ACLK              (ACLK),
        .ARESETn           (ARESETn),

        // AXI-Lite command information
        .Start_pulse       (Start_pulse),
        .Mode              (Mode),
        .Src_addr          (Src_addr),
        .Dst_addr          (Dst_addr),

        // Input loader
        .Load_start        (Load_start),
        .Load_done         (Load_done),

        // NTT core
        .Core_start        (Core_start),
        .Core_fin          (Core_fin),

        // Output writer
        .Write_start       (Write_start),
        .Write_done        (Write_done),

        // Latched command
        .Mode_latched      (Mode_latched),
        .Src_addr_latched  (Src_addr_latched),
        .Dst_addr_latched  (Dst_addr_latched),

        // Status
        .Busy              (Busy),
        .Done              (Done),
        .Error             (Error)
    );


    //==================================================================
    // Clock Generation
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
    // Waveform Dump
    //==================================================================

    initial begin

        $dumpfile("Acc_Controller_tb.vcd");
        $dumpvars(0, tb_Acc_Controller);

    end


    //==================================================================
    // CHECK_1
    //
    // Self-checking helper for 1-bit signals.
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
    // CHECK_32
    //
    // Self-checking helper for 32-bit signals.
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
    // RESET_DUT
    //==================================================================

    task RESET_DUT;

        begin

            //----------------------------------------------------------
            // Put all inputs into inactive state.
            //----------------------------------------------------------

            Start_pulse = 1'b0;

            Mode     = 1'b0;
            Src_addr = 32'b0;
            Dst_addr = 32'b0;

            Load_done  = 1'b0;
            Core_fin   = 1'b0;
            Write_done = 1'b0;


            //----------------------------------------------------------
            // Assert active-low reset.
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
            // This prevents TB/DUT race around the active clock edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            ARESETn = 1'b1;


            //----------------------------------------------------------
            // Wait one normal cycle.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;

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

        Start_pulse = 1'b0;

        Mode     = 1'b0;
        Src_addr = 32'b0;
        Dst_addr = 32'b0;

        Load_done  = 1'b0;
        Core_fin   = 1'b0;
        Write_done = 1'b0;


        //==============================================================
        // TEST 1: RESET
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 1: RESET");
        $display("================================================");


        RESET_DUT();


        CHECK_1(
            Busy,
            1'b0,
            "Reset Busy"
        );

        CHECK_1(
            Done,
            1'b0,
            "Reset Done"
        );

        CHECK_1(
            Error,
            1'b0,
            "Reset Error"
        );

        CHECK_1(
            Load_start,
            1'b0,
            "Reset Load_start"
        );

        CHECK_1(
            Core_start,
            1'b0,
            "Reset Core_start"
        );

        CHECK_1(
            Write_start,
            1'b0,
            "Reset Write_start"
        );

        CHECK_32(
            Src_addr_latched,
            32'h0000_0000,
            "Reset Src_addr_latched"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h0000_0000,
            "Reset Dst_addr_latched"
        );


        //==============================================================
        // TEST 2: START COMMAND
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 2: START COMMAND");
        $display("================================================");


        //--------------------------------------------------------------
        // Pretend these values came from AXI-Lite registers.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Mode     = 1'b1;
        Src_addr = 32'h1000_1000;
        Dst_addr = 32'h1000_2000;


        //--------------------------------------------------------------
        // Generate one-clock Start_pulse.
        //--------------------------------------------------------------

        Start_pulse = 1'b1;


        //--------------------------------------------------------------
        // At the next rising edge, controller is in IDLE and sees
        // Start_pulse = 1.
        //
        // It should:
        //
        //      latch configuration
        //      Busy       = 1
        //      Done       = 0
        //      Load_start = 1
        //      enter LOAD_INPUT
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b1,
            "Busy asserted after START"
        );

        CHECK_1(
            Done,
            1'b0,
            "Done cleared after START"
        );

        CHECK_1(
            Load_start,
            1'b1,
            "Load_start asserted"
        );

        CHECK_1(
            Mode_latched,
            1'b1,
            "Mode captured"
        );

        CHECK_32(
            Src_addr_latched,
            32'h1000_1000,
            "Source address captured"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h1000_2000,
            "Destination address captured"
        );


        //--------------------------------------------------------------
        // Remove CPU Start command.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Start_pulse = 1'b0;


        //--------------------------------------------------------------
        // Next clock:
        //
        // controller is now in LOAD_INPUT.
        //
        // Because Load_start defaults to 0 every cycle,
        // it should automatically return low.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Load_start,
            1'b0,
            "Load_start is one-cycle pulse"
        );

        CHECK_1(
            Busy,
            1'b1,
            "Busy remains high during LOAD"
        );


        //==============================================================
        // TEST 3: CONFIGURATION SNAPSHOT
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 3: CONFIGURATION SNAPSHOT");
        $display("================================================");


        //--------------------------------------------------------------
        // CPU changes its AXI register values WHILE accelerator is busy.
        //
        // Current transaction must NOT change.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Mode     = 1'b0;
        Src_addr = 32'hDEAD_BEEF;
        Dst_addr = 32'hCAFE_BABE;


        @(posedge ACLK);

        #1;


        //--------------------------------------------------------------
        // Latched values must still be the values from original START.
        //--------------------------------------------------------------

        CHECK_1(
            Mode_latched,
            1'b1,
            "Mode snapshot remains unchanged"
        );

        CHECK_32(
            Src_addr_latched,
            32'h1000_1000,
            "Src_addr snapshot remains unchanged"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h1000_2000,
            "Dst_addr snapshot remains unchanged"
        );


        //==============================================================
        // TEST 4: START WHILE BUSY
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 4: START WHILE BUSY");
        $display("================================================");


        //--------------------------------------------------------------
        // Controller is currently in LOAD_INPUT.
        //
        // Generate another START.
        //
        // Our first design intentionally only accepts START in IDLE.
        //
        // Therefore this command must be ignored.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Start_pulse = 1'b1;


        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b1,
            "Busy stays asserted"
        );

        CHECK_1(
            Load_start,
            1'b0,
            "Second START does not restart loader"
        );

        CHECK_32(
            Src_addr_latched,
            32'h1000_1000,
            "Busy START does not overwrite source address"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h1000_2000,
            "Busy START does not overwrite destination address"
        );


        @(negedge ACLK);

        Start_pulse = 1'b0;


        //==============================================================
        // TEST 5: LOAD_DONE -> CORE_START
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 5: LOAD_DONE -> CORE_START");
        $display("================================================");


        //--------------------------------------------------------------
        // Input loader tells controller:
        //
        //      all 256 coefficients have been loaded.
        //--------------------------------------------------------------

        Load_done = 1'b1;


        //--------------------------------------------------------------
        // Rising edge in STATE_LOAD_INPUT:
        //
        //      Load_done = 1
        //
        // causes:
        //
        //      next state = PREP_CORE
        //
        // Core_start is NOT high yet.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Core_start,
            1'b0,
            "Core_start not asserted immediately with Load_done"
        );


        //--------------------------------------------------------------
        // Load_done is treated as a completion pulse.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Load_done = 1'b0;


        //--------------------------------------------------------------
        // Next rising edge executes STATE_PREP_CORE.
        //
        // Controller now generates:
        //
        //      Core_start = 1
        //
        // and transitions to RUN_CORE.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Core_start,
            1'b1,
            "Core_start asserted after preparation"
        );

        CHECK_1(
            Busy,
            1'b1,
            "Busy remains high while core starts"
        );


        //--------------------------------------------------------------
        // One clock later, state is RUN_CORE.
        //
        // Core_start must return to zero.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Core_start,
            1'b0,
            "Core_start is one-cycle pulse"
        );


        //==============================================================
        // TEST 6: CORE_FIN -> WRITE_START
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 6: CORE_FIN -> WRITE_START");
        $display("================================================");


        //--------------------------------------------------------------
        // Thesis core finishes.
        //
        // Core_fin corresponds to your original Fin signal.
        //
        // It occurs together with the final valid output group.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Core_fin = 1'b1;


        //--------------------------------------------------------------
        // Rising edge in RUN_CORE:
        //
        //      Core_fin = 1
        //
        // only moves controller to PREP_WRITE.
        //
        // We intentionally do NOT start memory writeback yet.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b0,
            "Write_start not asserted immediately with Core_fin"
        );


        //--------------------------------------------------------------
        // Remove core Fin.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Core_fin = 1'b0;


        //--------------------------------------------------------------
        // Next rising edge executes PREP_WRITE.
        //
        // Final four coefficients should already be safely captured.
        //
        // Now:
        //
        //      Write_start = 1
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b1,
            "Write_start asserted after preparation"
        );


        //--------------------------------------------------------------
        // Next cycle enters WRITE_OUTPUT.
        //
        // Write_start must fall back to zero.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b0,
            "Write_start is one-cycle pulse"
        );

        CHECK_1(
            Busy,
            1'b1,
            "Busy remains high during writeback"
        );


        //==============================================================
        // TEST 7: WRITE_DONE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 7: WRITE_DONE");
        $display("================================================");


        //--------------------------------------------------------------
        // Future AXI4 writer reports:
        //
        //      all output coefficients have been written to memory.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Write_done = 1'b1;


        //--------------------------------------------------------------
        // Rising edge in WRITE_OUTPUT:
        //
        //      Write_done = 1
        //
        // means entire accelerator command is complete.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Busy clears after Write_done"
        );

        CHECK_1(
            Done,
            1'b1,
            "Done asserted after Write_done"
        );


        @(negedge ACLK);

        Write_done = 1'b0;


        //==============================================================
        // TEST 8: DONE IS STICKY
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 8: DONE STICKY FLAG");
        $display("================================================");


        //--------------------------------------------------------------
        // Controller is now back in IDLE.
        //
        // Done must NOT disappear automatically.
        //
        // Software may poll STATUS much later.
        //--------------------------------------------------------------

        repeat(3) begin

            @(posedge ACLK);

            #1;


            CHECK_1(
                Done,
                1'b1,
                "Done remains high in IDLE"
            );

            CHECK_1(
                Busy,
                1'b0,
                "Busy remains low in IDLE"
            );

        end


        //==============================================================
        // TEST 9: NEXT START CLEARS DONE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 9: NEXT START CLEARS DONE");
        $display("================================================");


        //--------------------------------------------------------------
        // Program completely different configuration.
        //--------------------------------------------------------------

        @(negedge ACLK);

        Mode     = 1'b0;
        Src_addr = 32'h2000_1000;
        Dst_addr = 32'h2000_2000;

        Start_pulse = 1'b1;


        //--------------------------------------------------------------
        // New operation begins.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Done,
            1'b0,
            "New START clears previous Done"
        );

        CHECK_1(
            Busy,
            1'b1,
            "New START asserts Busy"
        );

        CHECK_1(
            Load_start,
            1'b1,
            "New START generates Load_start"
        );

        CHECK_1(
            Mode_latched,
            1'b0,
            "New Mode captured"
        );

        CHECK_32(
            Src_addr_latched,
            32'h2000_1000,
            "New source address captured"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h2000_2000,
            "New destination address captured"
        );


        @(negedge ACLK);

        Start_pulse = 1'b0;


        //==============================================================
        // TEST 10: ASYNCHRONOUS RESET WHILE BUSY
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 10: ASYNC RESET WHILE BUSY");
        $display("================================================");


        //--------------------------------------------------------------
        // Controller is currently busy in LOAD_INPUT.
        //
        // Assert ARESETn between clock edges.
        //
        // Because DUT uses asynchronous reset,
        // outputs should reset without waiting for next posedge.
        //--------------------------------------------------------------

        #2;

        ARESETn = 1'b0;

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Async reset clears Busy"
        );

        CHECK_1(
            Done,
            1'b0,
            "Async reset clears Done"
        );

        CHECK_1(
            Load_start,
            1'b0,
            "Async reset clears Load_start"
        );

        CHECK_1(
            Core_start,
            1'b0,
            "Async reset clears Core_start"
        );

        CHECK_1(
            Write_start,
            1'b0,
            "Async reset clears Write_start"
        );

        CHECK_32(
            Src_addr_latched,
            32'h0000_0000,
            "Async reset clears source snapshot"
        );

        CHECK_32(
            Dst_addr_latched,
            32'h0000_0000,
            "Async reset clears destination snapshot"
        );


        //==============================================================
        // FINAL SUMMARY
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
            $display("==============================================");
            $display("ALL ACCELERATOR CONTROLLER TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("ACCELERATOR CONTROLLER TEST FAILED");
            $display("==============================================");

        end


        #20;

        $finish;

    end


endmodule
