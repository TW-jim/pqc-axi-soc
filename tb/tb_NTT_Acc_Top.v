`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: tb_NTT_Acc_Top
//
// Integration coverage:
//
//   AXI4-Lite control path
//          +
//   Accelerator Controller
//          +
//   AXI4 Read Loader
//          +
//   Input Buffer
//
//----------------------------------------------------------------------
// End-to-end path:
//
//   CPU programs SRC_ADDR / DST_ADDR / MODE / START
//                     |
//                     v
//             Acc_Controller
//                     |
//                 Load_start
//                     |
//                     v
//             AXI_Read_Loader
//                     |
//             AXI4 Read Bursts
//                     |
//                     v
//               Input_Buffer
//                     |
//                 Load_done
//                     |
//                     v
//                 Core_start
//
//======================================================================

module tb_NTT_Acc_Top;


    //==================================================================
    // Configuration
    //==================================================================

    localparam COEFF_WIDTH = 23;

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
    // AXI4-Lite Slave Interface
    //
    // TB acts as CPU / AXI4-Lite Master.
    //==================================================================

    // AW
    reg  [31:0] S_AXI_AWADDR;
    reg         S_AXI_AWVALID;
    wire        S_AXI_AWREADY;

    // W
    reg  [31:0] S_AXI_WDATA;
    reg  [3:0]  S_AXI_WSTRB;
    reg         S_AXI_WVALID;
    wire        S_AXI_WREADY;

    // B
    wire [1:0] S_AXI_BRESP;
    wire       S_AXI_BVALID;
    reg        S_AXI_BREADY;

    // AR
    reg  [31:0] S_AXI_ARADDR;
    reg         S_AXI_ARVALID;
    wire        S_AXI_ARREADY;

    // R
    wire [31:0] S_AXI_RDATA;
    wire [1:0]  S_AXI_RRESP;
    wire        S_AXI_RVALID;
    reg         S_AXI_RREADY;


    //==================================================================
    // AXI4 Full Read Master Interface
    //
    // DUT is Master.
    // TB acts as system-memory Slave.
    //==================================================================

    // AR
    wire [31:0] M_AXI_ARADDR;
    wire [7:0]  M_AXI_ARLEN;
    wire [2:0]  M_AXI_ARSIZE;
    wire [1:0]  M_AXI_ARBURST;
    wire        M_AXI_ARVALID;
    reg         M_AXI_ARREADY;

    // R
    reg  [31:0] M_AXI_RDATA;
    reg  [1:0]  M_AXI_RRESP;
    reg         M_AXI_RVALID;
    reg         M_AXI_RLAST;
    wire        M_AXI_RREADY;


    //==================================================================
    // Temporary Core / Writer Interface
    //==================================================================

    wire Core_start;
    reg  Core_fin;

    wire Write_start;
    reg  Write_done;


    //==================================================================
    // Input Buffer Debug Read Ports
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
    // Status / Debug
    //==================================================================

    wire Busy;
    wire Done;
    wire Error;

    wire Load_busy;
    wire Load_error;

    wire        Mode_latched;
    wire [31:0] Src_addr_latched;
    wire [31:0] Dst_addr_latched;


    //==================================================================
    // TB Variables
    //==================================================================

    integer test_count;
    integer error_count;

    integer burst;
    integer beat;
    integer global_index;

    reg [31:0] read_value;


    //==================================================================
    // DUT
    //==================================================================

    NTT_Acc_Top #(

        .COEFF_WIDTH(COEFF_WIDTH)

    ) DUT (

        .ACLK               (ACLK),
        .ARESETn            (ARESETn),

        //==============================================================
        // AXI4-Lite
        //==============================================================

        .S_AXI_AWADDR       (S_AXI_AWADDR),
        .S_AXI_AWVALID      (S_AXI_AWVALID),
        .S_AXI_AWREADY      (S_AXI_AWREADY),

        .S_AXI_WDATA        (S_AXI_WDATA),
        .S_AXI_WSTRB        (S_AXI_WSTRB),
        .S_AXI_WVALID       (S_AXI_WVALID),
        .S_AXI_WREADY       (S_AXI_WREADY),

        .S_AXI_BRESP        (S_AXI_BRESP),
        .S_AXI_BVALID       (S_AXI_BVALID),
        .S_AXI_BREADY       (S_AXI_BREADY),

        .S_AXI_ARADDR       (S_AXI_ARADDR),
        .S_AXI_ARVALID      (S_AXI_ARVALID),
        .S_AXI_ARREADY      (S_AXI_ARREADY),

        .S_AXI_RDATA        (S_AXI_RDATA),
        .S_AXI_RRESP        (S_AXI_RRESP),
        .S_AXI_RVALID       (S_AXI_RVALID),
        .S_AXI_RREADY       (S_AXI_RREADY),


        //==============================================================
        // AXI4 Full Read Master
        //==============================================================

        .M_AXI_ARADDR       (M_AXI_ARADDR),
        .M_AXI_ARLEN        (M_AXI_ARLEN),
        .M_AXI_ARSIZE       (M_AXI_ARSIZE),
        .M_AXI_ARBURST      (M_AXI_ARBURST),
        .M_AXI_ARVALID      (M_AXI_ARVALID),
        .M_AXI_ARREADY      (M_AXI_ARREADY),

        .M_AXI_RDATA        (M_AXI_RDATA),
        .M_AXI_RRESP        (M_AXI_RRESP),
        .M_AXI_RVALID       (M_AXI_RVALID),
        .M_AXI_RLAST        (M_AXI_RLAST),
        .M_AXI_RREADY       (M_AXI_RREADY),


        //==============================================================
        // Core / Writer
        //==============================================================

        .Core_start         (Core_start),
        .Core_fin           (Core_fin),

        .Write_start        (Write_start),
        .Write_done         (Write_done),


        //==============================================================
        // Input Buffer debug ports
        //==============================================================

        .Buffer_R_addr_1    (Buffer_R_addr_1),
        .Buffer_R_addr_2    (Buffer_R_addr_2),
        .Buffer_R_addr_3    (Buffer_R_addr_3),
        .Buffer_R_addr_4    (Buffer_R_addr_4),

        .Buffer_R_data_1    (Buffer_R_data_1),
        .Buffer_R_data_2    (Buffer_R_data_2),
        .Buffer_R_data_3    (Buffer_R_data_3),
        .Buffer_R_data_4    (Buffer_R_data_4),


        //==============================================================
        // Status
        //==============================================================

        .Busy               (Busy),
        .Done               (Done),
        .Error              (Error),

        .Load_busy          (Load_busy),
        .Load_error         (Load_error),

        .Mode_latched       (Mode_latched),
        .Src_addr_latched   (Src_addr_latched),
        .Dst_addr_latched   (Dst_addr_latched)
    );


    //==================================================================
    // Clock
    //
    // 10 ns = 100 MHz
    //==================================================================

    initial begin

        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;

    end


    //==================================================================
    // Waveform
    //==================================================================

    initial begin

        $dumpfile("NTT_Acc_Top_tb.vcd");

        $dumpvars(
            0,
            tb_NTT_Acc_Top
        );

    end


    //==================================================================
    // CHECK_1
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


    //==================================================================
    // CHECK_32
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
    // AXI-Lite SEND_AW
    //==================================================================

    task automatic SEND_AW;

        input [31:0] Address;

        begin

            @(negedge ACLK);

            S_AXI_AWADDR  = Address;
            S_AXI_AWVALID = 1'b1;


            @(posedge ACLK);

            while(S_AXI_AWREADY !== 1'b1)
                @(posedge ACLK);


            @(negedge ACLK);

            S_AXI_AWVALID = 1'b0;

        end

    endtask


    //==================================================================
    // AXI-Lite SEND_W
    //==================================================================

    task automatic SEND_W;

        input [31:0] Data;

        begin

            @(negedge ACLK);

            S_AXI_WDATA  = Data;
            S_AXI_WSTRB  = 4'b1111;
            S_AXI_WVALID = 1'b1;


            @(posedge ACLK);

            while(S_AXI_WREADY !== 1'b1)
                @(posedge ACLK);


            @(negedge ACLK);

            S_AXI_WVALID = 1'b0;

        end

    endtask


    //==================================================================
    // AXI-Lite WRITE
    //==================================================================

    task automatic AXI_WRITE;

        input [31:0] Address;
        input [31:0] Data;

        begin

            fork

                SEND_AW(Address);

                SEND_W(Data);

            join


            //----------------------------------------------------------
            // Wait write response.
            //----------------------------------------------------------

            wait(S_AXI_BVALID === 1'b1);

            #1;


            if(S_AXI_BRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] AXI-Lite BRESP=%b",
                    S_AXI_BRESP
                );

            end


            //----------------------------------------------------------
            // Accept response.
            //----------------------------------------------------------

            @(negedge ACLK);

            S_AXI_BREADY = 1'b1;


            @(posedge ACLK);

            #1;


            if(S_AXI_BVALID !== 1'b0) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] AXI-Lite BVALID did not clear"
                );

            end


            @(negedge ACLK);

            S_AXI_BREADY = 1'b0;

        end

    endtask


    //==================================================================
    // AXI-Lite READ
    //==================================================================

    task automatic AXI_READ;

        input  [31:0] Address;
        output [31:0] Data;

        begin

            @(negedge ACLK);

            S_AXI_ARADDR  = Address;
            S_AXI_ARVALID = 1'b1;


            @(posedge ACLK);

            while(S_AXI_ARREADY !== 1'b1)
                @(posedge ACLK);


            @(negedge ACLK);

            S_AXI_ARVALID = 1'b0;


            wait(S_AXI_RVALID === 1'b1);

            #1;

            Data = S_AXI_RDATA;


            if(S_AXI_RRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] AXI-Lite RRESP=%b",
                    S_AXI_RRESP
                );

            end


            @(negedge ACLK);

            S_AXI_RREADY = 1'b1;


            @(posedge ACLK);

            #1;


            if(S_AXI_RVALID !== 1'b0) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] AXI-Lite RVALID did not clear"
                );

            end


            @(negedge ACLK);

            S_AXI_RREADY = 1'b0;

        end

    endtask


    //==================================================================
    // SEND_ONE_MEMORY_R_BEAT
    //
    // TB = AXI4 memory slave.
    //==================================================================

    task automatic SEND_ONE_MEMORY_R_BEAT;

        input [31:0] Data;
        input Last;

        begin

            @(negedge ACLK);

            M_AXI_RDATA  = Data;
            M_AXI_RRESP  = 2'b00;
            M_AXI_RLAST  = Last;
            M_AXI_RVALID = 1'b1;


            //----------------------------------------------------------
            // Wait until Loader is ready.
            //----------------------------------------------------------

            @(posedge ACLK);

            while(M_AXI_RREADY !== 1'b1)
                @(posedge ACLK);


            //----------------------------------------------------------
            // R handshake occurred.
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


        //==============================================================
        // Initial values
        //==============================================================

        test_count  = 0;
        error_count = 0;

        ARESETn = 1'b0;


        // AXI-Lite
        S_AXI_AWADDR  = 32'b0;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA   = 32'b0;
        S_AXI_WSTRB   = 4'b0;
        S_AXI_WVALID  = 1'b0;

        S_AXI_BREADY  = 1'b0;

        S_AXI_ARADDR  = 32'b0;
        S_AXI_ARVALID = 1'b0;

        S_AXI_RREADY  = 1'b0;


        // AXI4 memory
        M_AXI_ARREADY = 1'b0;

        M_AXI_RDATA   = 32'b0;
        M_AXI_RRESP   = 2'b00;
        M_AXI_RVALID  = 1'b0;
        M_AXI_RLAST   = 1'b0;


        // Core / writer
        Core_fin   = 1'b0;
        Write_done = 1'b0;


        // Buffer debug
        Buffer_R_addr_1 = 8'd0;
        Buffer_R_addr_2 = 8'd0;
        Buffer_R_addr_3 = 8'd0;
        Buffer_R_addr_4 = 8'd0;


        //==============================================================
        // TEST 1: RESET
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 1: RESET");
        $display("================================================");


        repeat(2)
            @(posedge ACLK);


        @(negedge ACLK);

        ARESETn = 1'b1;


        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Reset accelerator Busy"
        );

        CHECK_1(
            Done,
            1'b0,
            "Reset accelerator Done"
        );

        CHECK_1(
            Error,
            1'b0,
            "Accelerator Error remains low"
        );

        CHECK_1(
            Load_busy,
            1'b0,
            "Reset Loader Busy"
        );


        //==============================================================
        // TEST 2: PROGRAM REGISTERS
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 2: PROGRAM ACCELERATOR");
        $display("================================================");


        AXI_WRITE(
            ADDR_SRC_ADDR,
            32'h1000_1000
        );


        AXI_WRITE(
            ADDR_DST_ADDR,
            32'h1000_2000
        );


        //--------------------------------------------------------------
        // CONTROL:
        //
        // bit1 MODE  = 1
        // bit0 START = 1
        //--------------------------------------------------------------

        AXI_WRITE(
            ADDR_CONTROL,
            32'h0000_0003
        );


        //--------------------------------------------------------------
        // Controller should have latched configuration.
        //--------------------------------------------------------------

        CHECK_1(
            Busy,
            1'b1,
            "Accelerator Busy after AXI START"
        );


        CHECK_1(
            Mode_latched,
            1'b1,
            "Mode latched"
        );


        CHECK_32(
            Src_addr_latched,
            32'h1000_1000,
            "Source address latched"
        );


        CHECK_32(
            Dst_addr_latched,
            32'h1000_2000,
            "Destination address latched"
        );


        //==============================================================
        // TEST 3: SOFTWARE SEES BUSY
        //==============================================================

        AXI_READ(
            ADDR_STATUS,
            read_value
        );


        CHECK_32(
            read_value,
            32'h0000_0001,
            "STATUS reports Busy"
        );


        //==============================================================
        // TEST 4: AXI4 MEMORY LOAD
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 4: AXI4 MEMORY LOAD");
        $display("================================================");


        global_index = 0;


        for(burst = 0; burst < 16; burst = burst + 1) begin


            //----------------------------------------------------------
            // Wait for Loader's AR request.
            //----------------------------------------------------------

            wait(M_AXI_ARVALID === 1'b1);

            #1;


            //----------------------------------------------------------
            // Loader MUST continue using the originally latched
            // Src_addr.
            //----------------------------------------------------------

            CHECK_32(
                M_AXI_ARADDR,
                32'h1000_1000 + (burst * 64),
                "AXI4 burst address"
            );


            //----------------------------------------------------------
            // Burst attributes.
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


            //==========================================================
            // During burst #1, deliberately change CPU-visible
            // configuration while ARREADY is still LOW.
            //
            // This tests TWO things at once:
            //
            //   1. AXI ARADDR stability under backpressure.
            //   2. Controller configuration snapshot.
            //==========================================================

            if(burst == 1) begin


                //------------------------------------------------------
                // ARVALID is already asserted.
                // ARREADY remains 0.
                //------------------------------------------------------

                AXI_WRITE(
                    ADDR_SRC_ADDR,
                    32'hDEAD_BEEF
                );


                AXI_WRITE(
                    ADDR_DST_ADDR,
                    32'hCAFE_BABE
                );


                //------------------------------------------------------
                // CPU-visible values changed.
                //------------------------------------------------------

                AXI_READ(
                    ADDR_SRC_ADDR,
                    read_value
                );


                CHECK_32(
                    read_value,
                    32'hDEAD_BEEF,
                    "CPU-visible SRC changed while Busy"
                );


                AXI_READ(
                    ADDR_DST_ADDR,
                    read_value
                );


                CHECK_32(
                    read_value,
                    32'hCAFE_BABE,
                    "CPU-visible DST changed while Busy"
                );


                //------------------------------------------------------
                // Current transaction snapshot MUST NOT change.
                //------------------------------------------------------

                CHECK_32(
                    Src_addr_latched,
                    32'h1000_1000,
                    "Current Src snapshot unchanged"
                );


                CHECK_32(
                    Dst_addr_latched,
                    32'h1000_2000,
                    "Current Dst snapshot unchanged"
                );


                //------------------------------------------------------
                // AXI4 AR payload must also still be the same request.
                //------------------------------------------------------

                CHECK_32(
                    M_AXI_ARADDR,
                    32'h1000_1040,
                    "ARADDR stable during CPU reprogramming"
                );

            end


            //----------------------------------------------------------
            // Accept AXI4 AR request.
            //----------------------------------------------------------

            @(negedge ACLK);

            M_AXI_ARREADY = 1'b1;


            @(posedge ACLK);

            #1;


            CHECK_1(
                M_AXI_ARVALID,
                1'b0,
                "ARVALID clears after handshake"
            );


            @(negedge ACLK);

            M_AXI_ARREADY = 1'b0;


            //----------------------------------------------------------
            // Return 16 R beats.
            //----------------------------------------------------------

            for(beat = 0; beat < 16; beat = beat + 1) begin


                //------------------------------------------------------
                // Occasionally leave RVALID low for one cycle.
                //------------------------------------------------------

                if((beat % 5) == 0)
                    @(posedge ACLK);


                //------------------------------------------------------
                // Memory content:
                //
                // coefficient[i] = 0x00500000 + i
                //------------------------------------------------------

                SEND_ONE_MEMORY_R_BEAT(

                    32'h0050_0000 + global_index,

                    (beat == 15)

                );


                global_index = global_index + 1;

            end

        end


        //==============================================================
        // TEST 5: INPUT BUFFER CONTENT
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 5: INPUT BUFFER CONTENT");
        $display("================================================");


        //--------------------------------------------------------------
        // Loader itself should now be idle.
        //
        // Controller remains Busy because NTT core has not run yet.
        //--------------------------------------------------------------

        #1;


        CHECK_1(
            Load_busy,
            1'b0,
            "Loader finished"
        );


        CHECK_1(
            Load_error,
            1'b0,
            "Loader completed without error"
        );


        CHECK_1(
            Busy,
            1'b1,
            "Accelerator remains Busy after load"
        );


        //--------------------------------------------------------------
        // Verify arbitrary buffer locations.
        //--------------------------------------------------------------

        Buffer_R_addr_1 = 8'd0;
        Buffer_R_addr_2 = 8'd1;
        Buffer_R_addr_3 = 8'd127;
        Buffer_R_addr_4 = 8'd255;

        #1;


        CHECK_32(
            {9'b0, Buffer_R_data_1},
            32'h0050_0000,
            "Input buffer[0]"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_2},
            32'h0050_0001,
            "Input buffer[1]"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_3},
            32'h0050_007F,
            "Input buffer[127]"
        );


        CHECK_32(
            {9'b0, Buffer_R_data_4},
            32'h0050_00FF,
            "Input buffer[255]"
        );


        //==============================================================
        // TEST 6: LOAD_DONE -> CORE_START
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 6: LOAD_DONE -> CORE_START");
        $display("================================================");


        //--------------------------------------------------------------
        // Because Load_done travels:
        //
        // Loader -> Controller -> PREP_CORE -> Core_start
        //
        // there are sequential boundaries here.
        //
        // Wait for the actual Core_start rather than assuming a fixed
        // simulation delay.
        //--------------------------------------------------------------

        wait(Core_start === 1'b1);

        #1;


        CHECK_1(
            Core_start,
            1'b1,
            "Core_start generated after memory load"
        );


        //--------------------------------------------------------------
        // It must only be one clock.
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Core_start,
            1'b0,
            "Core_start is one-cycle pulse"
        );


        //==============================================================
        // TEST 7: FAKE CORE EXECUTION
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 7: CORE COMPLETION");
        $display("================================================");


        //--------------------------------------------------------------
        // Pretend thesis NTT runs for 8 cycles.
        //--------------------------------------------------------------

        repeat(8)
            @(posedge ACLK);


        @(negedge ACLK);

        Core_fin = 1'b1;


        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b0,
            "Write_start waits for PREP_WRITE"
        );


        @(negedge ACLK);

        Core_fin = 1'b0;


        //--------------------------------------------------------------
        // PREP_WRITE -> Write_start
        //--------------------------------------------------------------

        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b1,
            "Write_start generated after Core_fin"
        );


        @(posedge ACLK);

        #1;


        CHECK_1(
            Write_start,
            1'b0,
            "Write_start is one-cycle pulse"
        );


        //==============================================================
        // TEST 8: FAKE WRITEBACK COMPLETION
        //==============================================================

        repeat(5)
            @(posedge ACLK);


        @(negedge ACLK);

        Write_done = 1'b1;


        @(posedge ACLK);

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Accelerator Busy clears after Write_done"
        );


        CHECK_1(
            Done,
            1'b1,
            "Accelerator Done asserted"
        );


        @(negedge ACLK);

        Write_done = 1'b0;


        //==============================================================
        // TEST 9: SOFTWARE READS DONE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 9: SOFTWARE STATUS READ");
        $display("================================================");


        AXI_READ(
            ADDR_STATUS,
            read_value
        );


        CHECK_32(
            read_value,
            32'h0000_0002,
            "STATUS reports Done"
        );


        //==============================================================
        // TEST 10: SECOND COMMAND USES NEW CONFIGURATION
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 10: SECOND COMMAND");
        $display("================================================");


        //--------------------------------------------------------------
        // SRC/DST were modified during the previous operation:
        //
        // SRC = DEADBEEF
        // DST = CAFEBABE
        //
        // Start a second operation with MODE=0.
        //--------------------------------------------------------------

        AXI_WRITE(
            ADDR_CONTROL,
            32'h0000_0001
        );


        CHECK_1(
            Busy,
            1'b1,
            "Second command starts accelerator"
        );


        CHECK_1(
            Done,
            1'b0,
            "Second command clears sticky Done"
        );


        CHECK_1(
            Mode_latched,
            1'b0,
            "Second command latches Mode=0"
        );


        CHECK_32(
            Src_addr_latched,
            32'hDEAD_BEEF,
            "Second command latches new SRC"
        );


        CHECK_32(
            Dst_addr_latched,
            32'hCAFE_BABE,
            "Second command latches new DST"
        );


        //--------------------------------------------------------------
        // Do not run another full 256-beat transfer in this TB.
        // Reset instead.
        //--------------------------------------------------------------

        @(negedge ACLK);

        ARESETn = 1'b0;

        #1;


        CHECK_1(
            Busy,
            1'b0,
            "Final reset clears Busy"
        );


        //==============================================================
        // SUMMARY
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
            $display("==================================================");
            $display("ALL NTT ACCELERATOR READ-PATH TESTS PASSED");
            $display("==================================================");

        end
        else begin

            $display("");
            $display("==================================================");
            $display("NTT ACCELERATOR READ-PATH TEST FAILED");
            $display("==================================================");

        end


        #20;

        $finish;

    end

endmodule
