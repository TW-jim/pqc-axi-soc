`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: tb_NTT_AXIL_Regs
//
// Purpose:
//   Verify the AXI4-Lite READ and WRITE paths of NTT_AXIL_Regs.
//
//   In this testbench:
//
//       Testbench = AXI4-Lite Master
//       DUT       = AXI4-Lite Slave
//
//----------------------------------------------------------------------
// AXI4-Lite has five independent channels:
//
// WRITE:
//
//   1. AW = Write Address
//   2. W  = Write Data
//   3. B  = Write Response
//
// READ:
//
//   4. AR = Read Address
//   5. R  = Read Data / Response
//
//----------------------------------------------------------------------
// AXI Handshake Rule:
//
//   A transfer happens at a rising edge only when:
//
//       VALID == 1
//       AND
//       READY == 1
//
// Example:
//
//       VALID = 1
//       READY = 0
//
//   => No transfer.
//
//       VALID = 1
//       READY = 1
//
//   => Transfer occurs at that rising edge.
//
//======================================================================

module tb_NTT_AXIL_Regs;


    //==================================================================
    // Register Map
    //==================================================================
    //
    // Must match the address map in NTT_AXIL_Regs.v
    //
    // 0x00 CONTROL
    //      bit 0 = START command
    //      bit 1 = MODE
    //
    // 0x04 STATUS
    //      bit 0 = Busy
    //      bit 1 = Done
    //      bit 2 = Error
    //
    // 0x08 SRC_ADDR
    //
    // 0x0C DST_ADDR
    //
    //==================================================================

    localparam [31:0] ADDR_CONTROL  = 32'h0000_0000;
    localparam [31:0] ADDR_STATUS   = 32'h0000_0004;
    localparam [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam [31:0] ADDR_DST_ADDR = 32'h0000_000C;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // AXI4-Lite Write Address Channel
    //
    // Master -> Slave:
    //
    //   AWADDR
    //   AWVALID
    //
    // Slave -> Master:
    //
    //   AWREADY
    //==================================================================

    reg  [31:0] S_AXI_AWADDR;
    reg         S_AXI_AWVALID;
    wire        S_AXI_AWREADY;


    //==================================================================
    // AXI4-Lite Write Data Channel
    //==================================================================

    reg  [31:0] S_AXI_WDATA;
    reg  [3:0]  S_AXI_WSTRB;
    reg         S_AXI_WVALID;
    wire        S_AXI_WREADY;


    //==================================================================
    // AXI4-Lite Write Response Channel
    //==================================================================

    wire [1:0]  S_AXI_BRESP;
    wire        S_AXI_BVALID;
    reg         S_AXI_BREADY;


    //==================================================================
    // AXI4-Lite Read Address Channel
    //
    // Master -> Slave:
    //
    //   ARADDR
    //   ARVALID
    //
    // Slave -> Master:
    //
    //   ARREADY
    //==================================================================

    reg  [31:0] S_AXI_ARADDR;
    reg         S_AXI_ARVALID;
    wire        S_AXI_ARREADY;


    //==================================================================
    // AXI4-Lite Read Data Channel
    //
    // Slave -> Master:
    //
    //   RDATA
    //   RRESP
    //   RVALID
    //
    // Master -> Slave:
    //
    //   RREADY
    //==================================================================

    wire [31:0] S_AXI_RDATA;
    wire [1:0]  S_AXI_RRESP;
    wire        S_AXI_RVALID;
    reg         S_AXI_RREADY;


    //==================================================================
    // Accelerator status inputs
    //
    // These are NOT AXI signals.
    //
    // Eventually these signals will come from Accel_Controller.
    //
    // For now the testbench directly drives them so that we can verify
    // the STATUS register read behavior.
    //==================================================================

    reg Busy;
    reg Done;
    reg Error;


    //==================================================================
    // Control outputs from register block
    //==================================================================

    wire        Start_pulse;
    wire        Mode;
    wire [31:0] Src_addr;
    wire [31:0] Dst_addr;


    //==================================================================
    // Testbench variables
    //==================================================================

    integer test_count;
    integer error_count;

    // Used to store AXI read results.
    reg [31:0] read_value;


    //==================================================================
    // DUT Instance
    //==================================================================

    NTT_AXIL_Regs DUT (

        // Clock / Reset
        .ACLK           (ACLK),
        .ARESETn        (ARESETn),

        //==============================================================
        // AXI Write Address Channel
        //==============================================================

        .S_AXI_AWADDR   (S_AXI_AWADDR),
        .S_AXI_AWVALID  (S_AXI_AWVALID),
        .S_AXI_AWREADY  (S_AXI_AWREADY),

        //==============================================================
        // AXI Write Data Channel
        //==============================================================

        .S_AXI_WDATA    (S_AXI_WDATA),
        .S_AXI_WSTRB    (S_AXI_WSTRB),
        .S_AXI_WVALID   (S_AXI_WVALID),
        .S_AXI_WREADY   (S_AXI_WREADY),

        //==============================================================
        // AXI Write Response Channel
        //==============================================================

        .S_AXI_BRESP    (S_AXI_BRESP),
        .S_AXI_BVALID   (S_AXI_BVALID),
        .S_AXI_BREADY   (S_AXI_BREADY),

        //==============================================================
        // AXI Read Address Channel
        //==============================================================

        .S_AXI_ARADDR   (S_AXI_ARADDR),
        .S_AXI_ARVALID  (S_AXI_ARVALID),
        .S_AXI_ARREADY  (S_AXI_ARREADY),

        //==============================================================
        // AXI Read Data Channel
        //==============================================================

        .S_AXI_RDATA    (S_AXI_RDATA),
        .S_AXI_RRESP    (S_AXI_RRESP),
        .S_AXI_RVALID   (S_AXI_RVALID),
        .S_AXI_RREADY   (S_AXI_RREADY),

        //==============================================================
        // Accelerator status
        //==============================================================

        .Busy           (Busy),
        .Done           (Done),
        .Error          (Error),

        //==============================================================
        // Control outputs
        //==============================================================

        .Start_pulse    (Start_pulse),
        .Mode           (Mode),
        .Src_addr       (Src_addr),
        .Dst_addr       (Dst_addr)
    );


    //==================================================================
    // Clock Generation
    //
    // Period = 10 ns
    //
    // Frequency:
    //
    //      1 / 10 ns = 100 MHz
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

        $dumpfile("NTT_AXIL_Regs_tb.vcd");

        // IMPORTANT:
        // The testbench module name is tb_NTT_AXIL_Regs.
        $dumpvars(0, tb_NTT_AXIL_Regs);

    end


    //==================================================================
    // CHECK_32
    //
    // Self-check helper for 32-bit values.
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
    // CHECK_1
    //
    // Self-check helper for 1-bit values.
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
    // Reset all Master-driven AXI signals and accelerator status inputs.
    //
    // ARESETn is active-low:
    //
    //      0 = reset
    //      1 = normal operation
    //==================================================================

    task RESET_DUT;

        begin

            //----------------------------------------------------------
            // Write channels -> idle
            //----------------------------------------------------------

            S_AXI_AWADDR  = 32'b0;
            S_AXI_AWVALID = 1'b0;

            S_AXI_WDATA   = 32'b0;
            S_AXI_WSTRB   = 4'b0;
            S_AXI_WVALID  = 1'b0;

            S_AXI_BREADY  = 1'b0;


            //----------------------------------------------------------
            // Read channels -> idle
            //----------------------------------------------------------

            S_AXI_ARADDR  = 32'b0;
            S_AXI_ARVALID = 1'b0;

            S_AXI_RREADY  = 1'b0;


            //----------------------------------------------------------
            // Accelerator status -> idle
            //----------------------------------------------------------

            Busy  = 1'b0;
            Done  = 1'b0;
            Error = 1'b0;


            //----------------------------------------------------------
            // Assert reset
            //----------------------------------------------------------

            ARESETn = 1'b0;

            repeat(2)
                @(posedge ACLK);


            //----------------------------------------------------------
            // Release reset at falling edge.
            //
            // This avoids a race with DUT sequential logic at posedge.
            //----------------------------------------------------------

            @(negedge ACLK);

            ARESETn = 1'b1;

            @(posedge ACLK);

            #1;

        end

    endtask


    //==================================================================
    // SEND_AW
    //
    // Send one AXI Write Address transaction.
    //==================================================================

    task automatic SEND_AW;

        input [31:0] Address;
        input integer Delay_cycles;

        integer i;

        begin

            for(i = 0; i < Delay_cycles; i = i + 1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // Drive signal at falling edge.
            //
            // This makes the signal stable before the next rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_AWADDR  = Address;
            S_AXI_AWVALID = 1'b1;


            //----------------------------------------------------------
            // Wait until:
            //
            //      AWVALID && AWREADY
            //
            // occurs at a rising edge.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(S_AXI_AWREADY !== 1'b1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // Handshake completed.
            //
            // Master can now deassert AWVALID.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_AWVALID = 1'b0;

        end

    endtask


    //==================================================================
    // SEND_W
    //
    // Send one AXI Write Data transaction.
    //
    // AW and W are independent channels.
    //==================================================================

    task automatic SEND_W;

        input [31:0] Data;
        input [3:0]  Wstrb;
        input integer Delay_cycles;

        integer i;

        begin

            for(i = 0; i < Delay_cycles; i = i + 1)
                @(posedge ACLK);


            @(negedge ACLK);

            S_AXI_WDATA  = Data;
            S_AXI_WSTRB  = Wstrb;
            S_AXI_WVALID = 1'b1;


            //----------------------------------------------------------
            // Wait for W handshake.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(S_AXI_WREADY !== 1'b1)
                @(posedge ACLK);


            @(negedge ACLK);

            S_AXI_WVALID = 1'b0;

        end

    endtask


    //==================================================================
    // WAIT_BVALID
    //
    // Wait for AXI Write Response.
    //==================================================================

    task automatic WAIT_BVALID;

        begin

            wait(S_AXI_BVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Current design always returns:
            //
            //      BRESP = 2'b00 = OKAY
            //----------------------------------------------------------

            if(S_AXI_BRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] BRESP should be OKAY, actual = %b",
                    S_AXI_BRESP
                );

            end

        end

    endtask


    //==================================================================
    // ACCEPT_B
    //
    // Accept the Write Response.
    //
    // Stall_cycles:
    //
    //   Number of clock cycles Master intentionally keeps BREADY low.
    //
    // This tests AXI backpressure.
    //==================================================================

    task automatic ACCEPT_B;

        input integer Stall_cycles;

        integer i;

        begin

            wait(S_AXI_BVALID === 1'b1);

            S_AXI_BREADY = 1'b0;


            //----------------------------------------------------------
            // During BREADY=0:
            //
            // BVALID must stay asserted.
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
            // Master accepts response.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_BREADY = 1'b1;


            //----------------------------------------------------------
            // BVALID && BREADY at this rising edge
            // completes the B transaction.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            //----------------------------------------------------------
            // DUT should clear BVALID.
            //----------------------------------------------------------

            if(S_AXI_BVALID !== 1'b0) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] BVALID did not clear after B handshake"
                );

            end


            @(negedge ACLK);

            S_AXI_BREADY = 1'b0;

        end

    endtask


    //==================================================================
    // AXI_WRITE
    //
    // Complete one AXI4-Lite Write transaction.
    //
    // fork...join is important because:
    //
    //      AW and W are independent channels.
    //
    // We must NOT artificially force:
    //
    //      AW -> W
    //
    // ordering.
    //==================================================================

    task automatic AXI_WRITE;

        input [31:0] Address;
        input [31:0] Data;
        input [3:0]  Wstrb;

        input integer AW_delay;
        input integer W_delay;
        input integer B_stall;

        begin

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


            WAIT_BVALID();

            ACCEPT_B(
                B_stall
            );

        end

    endtask


    //==================================================================
    // SEND_AR
    //
    // Send one AXI Read Address transaction.
    //
    // Read Address Channel:
    //
    //      Master                     Slave
    //
    //      ARADDR  ------------------>
    //      ARVALID ------------------>
    //      ARREADY <------------------
    //
    // Handshake:
    //
    //      ARVALID && ARREADY
    //
    //==================================================================

    task automatic SEND_AR;

        input [31:0] Address;
        input integer Delay_cycles;

        integer i;

        begin

            //----------------------------------------------------------
            // Optional delay
            //----------------------------------------------------------

            for(i = 0; i < Delay_cycles; i = i + 1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // Present ARADDR and ARVALID before next rising edge.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_ARADDR  = Address;
            S_AXI_ARVALID = 1'b1;


            //----------------------------------------------------------
            // Wait until Slave accepts the address.
            //
            // While ARREADY=0:
            //
            //      ARVALID must stay 1
            //      ARADDR must stay unchanged
            //----------------------------------------------------------

            @(posedge ACLK);

            while(S_AXI_ARREADY !== 1'b1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // AR handshake completed.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_ARVALID = 1'b0;

        end

    endtask


    //==================================================================
    // WAIT_RVALID
    //
    // Wait for the Slave to produce read data.
    //
    // RVALID means:
    //
    //      "RDATA and RRESP are valid."
    //
    //==================================================================

    task automatic WAIT_RVALID;

        begin

            wait(S_AXI_RVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Current design always uses:
            //
            //      RRESP = 00 = OKAY
            //----------------------------------------------------------

            if(S_AXI_RRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] RRESP should be OKAY, actual = %b",
                    S_AXI_RRESP
                );

            end

        end

    endtask


    //==================================================================
    // ACCEPT_R
    //
    // Accept one AXI Read Data transaction.
    //
    // Stall_cycles allows us to intentionally keep:
    //
    //      RREADY = 0
    //
    // after:
    //
    //      RVALID = 1
    //
    // AXI requires:
    //
    //      RVALID must stay HIGH
    //      RDATA  must stay stable
    //      RRESP  must stay stable
    //
    // until RVALID && RREADY handshake.
    //
    //==================================================================

    task automatic ACCEPT_R;

        input integer Stall_cycles;
        output [31:0] Read_data;

        integer i;

        reg [31:0] Held_data;
        reg [1:0]  Held_resp;

        begin

            //----------------------------------------------------------
            // Make sure response exists.
            //----------------------------------------------------------

            wait(S_AXI_RVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Capture the original response.
            //
            // During backpressure these values MUST NOT change.
            //----------------------------------------------------------

            Held_data = S_AXI_RDATA;
            Held_resp = S_AXI_RRESP;

            S_AXI_RREADY = 1'b0;


            //----------------------------------------------------------
            // Apply backpressure.
            //----------------------------------------------------------

            for(i = 0; i < Stall_cycles; i = i + 1) begin

                @(posedge ACLK);

                #1;


                //------------------------------------------------------
                // RVALID cannot disappear before RREADY handshake.
                //------------------------------------------------------

                if(S_AXI_RVALID !== 1'b1) begin

                    error_count = error_count + 1;

                    $display(
                        "[FAIL] RVALID dropped while RREADY = 0"
                    );

                end


                //------------------------------------------------------
                // RDATA cannot change while transaction is stalled.
                //------------------------------------------------------

                if(S_AXI_RDATA !== Held_data) begin

                    error_count = error_count + 1;

                    $display(
                        "[FAIL] RDATA changed while RREADY = 0"
                    );

                end


                //------------------------------------------------------
                // RRESP must also remain stable.
                //------------------------------------------------------

                if(S_AXI_RRESP !== Held_resp) begin

                    error_count = error_count + 1;

                    $display(
                        "[FAIL] RRESP changed while RREADY = 0"
                    );

                end


                //------------------------------------------------------
                // Our current Slave supports only one outstanding read.
                //
                // While RVALID is still pending:
                //
                //      ARREADY should be 0.
                //------------------------------------------------------

                if(S_AXI_ARREADY !== 1'b0) begin

                    error_count = error_count + 1;

                    $display(
                        "[FAIL] ARREADY should be low while RVALID is pending"
                    );

                end

            end


            //----------------------------------------------------------
            // Store returned data for caller.
            //----------------------------------------------------------

            Read_data = Held_data;


            //----------------------------------------------------------
            // Master becomes ready.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_RREADY = 1'b1;


            //----------------------------------------------------------
            // RVALID && RREADY at this rising edge:
            //
            //      Read transaction completes.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            //----------------------------------------------------------
            // DUT should clear RVALID after handshake.
            //----------------------------------------------------------

            if(S_AXI_RVALID !== 1'b0) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] RVALID did not clear after R handshake"
                );

            end


            @(negedge ACLK);

            S_AXI_RREADY = 1'b0;

        end

    endtask


    //==================================================================
    // AXI_READ
    //
    // Complete one AXI4-Lite Read transaction.
    //
    // Sequence:
    //
    //      1. Send ARADDR
    //      2. Wait for RVALID
    //      3. Optionally stall RREADY
    //      4. Accept RDATA
    //
    //==================================================================

    task automatic AXI_READ;

        input  [31:0] Address;
        input  integer R_stall;
        output [31:0] Read_data;

        begin

            //----------------------------------------------------------
            // Step 1: send read address
            //----------------------------------------------------------

            SEND_AR(
                Address,
                0
            );


            //----------------------------------------------------------
            // Step 2: wait for Slave read response
            //----------------------------------------------------------

            WAIT_RVALID();


            //----------------------------------------------------------
            // Step 3/4:
            //
            // optionally stall and then accept response.
            //----------------------------------------------------------

            ACCEPT_R(
                R_stall,
                Read_data
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


        // Write Master signals
        S_AXI_AWADDR  = 32'b0;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA   = 32'b0;
        S_AXI_WSTRB   = 4'b0;
        S_AXI_WVALID  = 1'b0;

        S_AXI_BREADY  = 1'b0;


        // Read Master signals
        S_AXI_ARADDR  = 32'b0;
        S_AXI_ARVALID = 1'b0;

        S_AXI_RREADY  = 1'b0;


        // Accelerator status
        Busy  = 1'b0;
        Done  = 1'b0;
        Error = 1'b0;


        //==============================================================
        // TEST 1: RESET
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

        CHECK_1(
            S_AXI_RVALID,
            1'b0,
            "Reset RVALID"
        );

        CHECK_32(
            S_AXI_RDATA,
            32'h0000_0000,
            "Reset RDATA"
        );


        //==============================================================
        // TEST 2: BASIC AXI WRITE
        //
        // AW and W arrive together.
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 2: BASIC AXI WRITE");
        $display("================================================");

        AXI_WRITE(
            ADDR_SRC_ADDR,
            32'h1234_5678,
            4'b1111,
            0,          // AW delay
            0,          // W delay
            0           // B stall
        );

        CHECK_32(
            Src_addr,
            32'h1234_5678,
            "Basic SRC_ADDR write"
        );


        //==============================================================
        // TEST 3: AW BEFORE W
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 3: AW BEFORE W");
        $display("================================================");

        AXI_WRITE(
            ADDR_DST_ADDR,
            32'hCAFE_BABE,
            4'b1111,
            0,          // AW immediately
            3,          // W 3 cycles later
            0
        );

        CHECK_32(
            Dst_addr,
            32'hCAFE_BABE,
            "AW before W"
        );


        //==============================================================
        // TEST 4: W BEFORE AW
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 4: W BEFORE AW");
        $display("================================================");

        AXI_WRITE(
            ADDR_SRC_ADDR,
            32'hDEAD_BEEF,
            4'b1111,
            3,          // AW later
            0,          // W immediately
            0
        );

        CHECK_32(
            Src_addr,
            32'hDEAD_BEEF,
            "W before AW"
        );


        //==============================================================
        // TEST 5: WSTRB PARTIAL WRITE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 5: WSTRB PARTIAL WRITE");
        $display("================================================");


        // First initialize value.
        AXI_WRITE(
            ADDR_SRC_ADDR,
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
        // WDATA = AABBCCDD
        //
        // WSTRB = 0010
        //
        // Only byte [15:8] is written.
        //
        // Expected:
        //
        //      11223344
        //          ↓
        //      1122CC44
        //--------------------------------------------------------------

        AXI_WRITE(
            ADDR_SRC_ADDR,
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
        // TEST 6: BREADY BACKPRESSURE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 6: BREADY BACKPRESSURE");
        $display("================================================");

        AXI_WRITE(
            ADDR_DST_ADDR,
            32'h5566_7788,
            4'b1111,
            0,
            0,
            3           // Hold BREADY low for 3 clocks
        );

        CHECK_32(
            Dst_addr,
            32'h5566_7788,
            "BREADY backpressure write"
        );


        //==============================================================
        // TEST 7: CONTROL / START / MODE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 7: CONTROL / START / MODE");
        $display("================================================");


        //--------------------------------------------------------------
        // CONTROL = 0x3
        //
        // bit 0 = START = 1
        // bit 1 = MODE  = 1
        //
        // We don't use AXI_WRITE because Start_pulse exists only
        // for one clock and we want to observe it before B finishes.
        //--------------------------------------------------------------

        fork

            SEND_AW(
                ADDR_CONTROL,
                0
            );

            SEND_W(
                32'h0000_0003,
                4'b1111,
                0
            );

        join


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
        // START must only last one clock.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Start_pulse,
            1'b0,
            "START pulse returns low"
        );


        //--------------------------------------------------------------
        // MODE is persistent.
        //--------------------------------------------------------------

        CHECK_1(
            Mode,
            1'b1,
            "MODE remains stored"
        );


        ACCEPT_B(
            0
        );


        //==============================================================
        // TEST 8: CONTROL WSTRB
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 8: CONTROL WSTRB");
        $display("================================================");

        //--------------------------------------------------------------
        // Mode is currently 1.
        //
        // Try:
        //
        //      CONTROL = 0
        //
        // but:
        //
        //      WSTRB = 1110
        //
        // WSTRB[0] = 0.
        //
        // Since START/MODE are inside byte 0,
        // Mode must NOT change.
        //--------------------------------------------------------------

        AXI_WRITE(
            ADDR_CONTROL,
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
        // TEST 9: READ SRC_ADDR
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 9: READ SRC_ADDR");
        $display("================================================");


        //--------------------------------------------------------------
        // Current Src_addr should still be:
        //
        //      0x1122CC44
        //
        // because TEST 5 was the last write to SRC_ADDR.
        //--------------------------------------------------------------

        AXI_READ(
            ADDR_SRC_ADDR,
            0,
            read_value
        );

        CHECK_32(
            read_value,
            32'h1122_CC44,
            "Read SRC_ADDR"
        );


        //==============================================================
        // TEST 10: READ DST_ADDR
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 10: READ DST_ADDR");
        $display("================================================");


        //--------------------------------------------------------------
        // TEST 6 last wrote:
        //
        //      DST_ADDR = 0x55667788
        //--------------------------------------------------------------

        AXI_READ(
            ADDR_DST_ADDR,
            0,
            read_value
        );

        CHECK_32(
            read_value,
            32'h5566_7788,
            "Read DST_ADDR"
        );


        //==============================================================
        // TEST 11: READ CONTROL
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 11: READ CONTROL");
        $display("================================================");


        //--------------------------------------------------------------
        // Current Mode = 1.
        //
        // CONTROL read format:
        //
        //      bit 0 = 0
        //              START is a command pulse, not stored state.
        //
        //      bit 1 = Mode = 1
        //
        // Therefore:
        //
        //      RDATA = 0x00000002
        //--------------------------------------------------------------

        AXI_READ(
            ADDR_CONTROL,
            0,
            read_value
        );

        CHECK_32(
            read_value,
            32'h0000_0002,
            "Read CONTROL"
        );


        //==============================================================
        // TEST 12: READ STATUS
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 12: READ STATUS");
        $display("================================================");


        //--------------------------------------------------------------
        // STATUS:
        //
        // bit 0 = Busy
        // bit 1 = Done
        // bit 2 = Error
        //
        // Set:
        //
        //      Busy  = 1
        //      Done  = 0
        //      Error = 1
        //
        // Binary:
        //
        //      101
        //
        // Hex:
        //
        //      0x5
        //--------------------------------------------------------------

        Busy  = 1'b1;
        Done  = 1'b0;
        Error = 1'b1;


        AXI_READ(
            ADDR_STATUS,
            0,
            read_value
        );


        CHECK_32(
            read_value,
            32'h0000_0005,
            "Read STATUS"
        );


        //==============================================================
        // TEST 13: RREADY BACKPRESSURE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 13: RREADY BACKPRESSURE");
        $display("================================================");


        //--------------------------------------------------------------
        // Read SRC_ADDR again.
        //
        // But this time:
        //
        //      R_stall = 3
        //
        // Master intentionally holds:
        //
        //      RREADY = 0
        //
        // for three clocks after RVALID appears.
        //
        // During these cycles:
        //
        //      RVALID must remain 1
        //      RDATA must remain unchanged
        //      RRESP must remain unchanged
        //--------------------------------------------------------------

        AXI_READ(
            ADDR_SRC_ADDR,
            3,
            read_value
        );


        CHECK_32(
            read_value,
            32'h1122_CC44,
            "RREADY backpressure"
        );


        //==============================================================
        // TEST 14: STATUS SNAPSHOT DURING BACKPRESSURE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 14: STATUS SNAPSHOT DURING R STALL");
        $display("================================================");


        //--------------------------------------------------------------
        // This test is important.
        //
        // At the moment of AR handshake:
        //
        //      Busy  = 1
        //      Done  = 0
        //      Error = 0
        //
        // Therefore expected STATUS:
        //
        //      001 = 0x1
        //--------------------------------------------------------------

        Busy  = 1'b1;
        Done  = 1'b0;
        Error = 1'b0;


        //--------------------------------------------------------------
        // Send STATUS read address.
        //--------------------------------------------------------------

        SEND_AR(
            ADDR_STATUS,
            0
        );


        //--------------------------------------------------------------
        // Wait until DUT produces RDATA.
        //--------------------------------------------------------------

        WAIT_RVALID();


        CHECK_32(
            S_AXI_RDATA,
            32'h0000_0001,
            "STATUS snapshot initial value"
        );


        //--------------------------------------------------------------
        // Master still has:
        //
        //      RREADY = 0
        //
        // Now deliberately change the REAL status inputs:
        //
        //      Busy  = 0
        //      Done  = 1
        //      Error = 1
        //
        // New live STATUS would be:
        //
        //      110 = 0x6
        //
        // BUT:
        //
        // the current AXI read transaction already returned 0x1.
        //
        // AXI requires RDATA to remain stable until the Master
        // accepts it.
        //--------------------------------------------------------------

        Busy  = 1'b0;
        Done  = 1'b1;
        Error = 1'b1;


        repeat(2) begin

            @(posedge ACLK);

            #1;


            CHECK_1(
                S_AXI_RVALID,
                1'b1,
                "RVALID held during STATUS change"
            );


            CHECK_32(
                S_AXI_RDATA,
                32'h0000_0001,
                "RDATA stable during STATUS change"
            );

        end


        //--------------------------------------------------------------
        // Accept the previously generated read response.
        //--------------------------------------------------------------

        ACCEPT_R(
            0,
            read_value
        );


        CHECK_32(
            read_value,
            32'h0000_0001,
            "STATUS transaction retained snapshot"
        );


        //==============================================================
        // TEST 15: UNDEFINED READ ADDRESS
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 15: UNDEFINED READ ADDRESS");
        $display("================================================");


        //--------------------------------------------------------------
        // Current DUT behavior for undefined address:
        //
        //      RDATA = 0
        //      RRESP = OKAY
        //
        // Later we may improve this to:
        //
        //      RRESP = SLVERR
        //--------------------------------------------------------------

        AXI_READ(
            32'h0000_0010,
            0,
            read_value
        );


        CHECK_32(
            read_value,
            32'h0000_0000,
            "Undefined address returns zero"
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
            $display("==============================================");
            $display("ALL AXI4-LITE READ/WRITE TESTS PASSED");
            $display("==============================================");

        end
        else begin

            $display("");
            $display("==============================================");
            $display("AXI4-LITE READ/WRITE TEST FAILED");
            $display("==============================================");

        end


        #20;

        $finish;

    end


endmodule
