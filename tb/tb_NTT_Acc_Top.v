`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
//======================================================================
// Testbench: tb_NTT_Acc_Top
//
// Full public-infrastructure integration test.
//
//----------------------------------------------------------------------
// Test flow:
//
//   1. CPU programs SRC_ADDR / DST_ADDR / MODE through AXI4-Lite.
//
//   2. CPU writes START.
//
//   3. Acc_Controller generates Load_start.
//
//   4. AXI_Read_Loader reads:
//
//          16 bursts
//          x 16 beats
//          = 256 coefficients
//
//   5. Input_Buffer contains all source coefficients.
//
//   6. Acc_Controller generates Core_start.
//
//   7. TB temporarily behaves like a fake compute core:
//
//          output[i] = input[i] + RESULT_OFFSET
//
//      Four coefficients are consumed / produced per cycle.
//
//   8. TB generates Core_fin.
//
//   9. Acc_Controller generates Write_start.
//
//  10. AXI_Write_Writer writes:
//
//          16 bursts
//          x 16 beats
//          = 256 coefficients
//
//  11. Final B response generates Write_done.
//
//  12. Acc_Controller sets:
//
//          Busy = 0
//          Done = 1
//
//  13. CPU reads STATUS through AXI4-Lite.
//
//======================================================================

module tb_NTT_Acc_Top;


    //==================================================================
    // Configuration
    //==================================================================

    localparam COEFF_WIDTH = 23;
    localparam ADDR_WIDTH  = 8;


    // AXI4-Lite register addresses
    localparam [31:0] ADDR_CONTROL  = 32'h0000_0000;
    localparam [31:0] ADDR_STATUS   = 32'h0000_0004;
    localparam [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam [31:0] ADDR_DST_ADDR = 32'h0000_000C;


    // Memory addresses used by current transaction.
    //
    // Both are 64-byte aligned.
    localparam [31:0] SRC_BASE_ADDR =
        32'h1000_1000;

    localparam [31:0] DST_BASE_ADDR =
        32'h2000_2000;


    // Values written by CPU DURING the current operation.
    //
    // These must NOT affect the current transaction.
    localparam [31:0] NEXT_SRC_ADDR =
        32'h3000_3000;

    localparam [31:0] NEXT_DST_ADDR =
        32'h4000_4000;


    // Source memory data:
    //
    //      source[i] = 0x100000 + i
    localparam [COEFF_WIDTH-1:0] SRC_DATA_BASE =
        23'h100000;


    // Fake compute:
    //
    //      result[i] = source[i] + 0x010000
    localparam [COEFF_WIDTH-1:0] RESULT_OFFSET =
        23'h010000;


    //==================================================================
    // Clock / Reset
    //==================================================================

    reg ACLK;
    reg ARESETn;


    //==================================================================
    // AXI4-Lite Slave Interface
    //
    // TB = CPU / AXI4-Lite Master
    // DUT = AXI4-Lite Slave
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
    // AXI4 Full Master -- Write Address
    //
    // DUT = Master
    // TB  = system-memory Slave
    //==================================================================

    wire [31:0] M_AXI_AWADDR;
    wire [7:0]  M_AXI_AWLEN;
    wire [2:0]  M_AXI_AWSIZE;
    wire [1:0]  M_AXI_AWBURST;

    wire M_AXI_AWVALID;
    reg  M_AXI_AWREADY;


    //==================================================================
    // AXI4 Full Master -- Write Data
    //==================================================================

    wire [31:0] M_AXI_WDATA;
    wire [3:0]  M_AXI_WSTRB;

    wire M_AXI_WLAST;
    wire M_AXI_WVALID;

    reg  M_AXI_WREADY;


    //==================================================================
    // AXI4 Full Master -- Write Response
    //==================================================================

    reg  [1:0] M_AXI_BRESP;
    reg        M_AXI_BVALID;

    wire       M_AXI_BREADY;


    //==================================================================
    // AXI4 Full Master -- Read Address
    //==================================================================

    wire [31:0] M_AXI_ARADDR;
    wire [7:0]  M_AXI_ARLEN;
    wire [2:0]  M_AXI_ARSIZE;
    wire [1:0]  M_AXI_ARBURST;

    wire M_AXI_ARVALID;
    reg  M_AXI_ARREADY;


    //==================================================================
    // AXI4 Full Master -- Read Data
    //==================================================================

    reg  [31:0] M_AXI_RDATA;
    reg  [1:0]  M_AXI_RRESP;
    reg         M_AXI_RVALID;
    reg         M_AXI_RLAST;

    wire        M_AXI_RREADY;


    //==================================================================
    // Temporary Core Interface
    //==================================================================

    wire Core_start;
    reg  Core_fin;


    //==================================================================
    // Input Buffer Read Ports
    //
    // TB uses these as the fake core input interface.
    //==================================================================

    reg [ADDR_WIDTH-1:0] Input_R_addr_1;
    reg [ADDR_WIDTH-1:0] Input_R_addr_2;
    reg [ADDR_WIDTH-1:0] Input_R_addr_3;
    reg [ADDR_WIDTH-1:0] Input_R_addr_4;

    wire [COEFF_WIDTH-1:0] Input_R_data_1;
    wire [COEFF_WIDTH-1:0] Input_R_data_2;
    wire [COEFF_WIDTH-1:0] Input_R_data_3;
    wire [COEFF_WIDTH-1:0] Input_R_data_4;


    //==================================================================
    // Output Buffer Write Ports
    //
    // TB uses these as the fake core output interface.
    //==================================================================

    reg Output_W_EN_1;
    reg Output_W_EN_2;
    reg Output_W_EN_3;
    reg Output_W_EN_4;

    reg [ADDR_WIDTH-1:0] Output_W_addr_1;
    reg [ADDR_WIDTH-1:0] Output_W_addr_2;
    reg [ADDR_WIDTH-1:0] Output_W_addr_3;
    reg [ADDR_WIDTH-1:0] Output_W_addr_4;

    reg [COEFF_WIDTH-1:0] Output_W_data_1;
    reg [COEFF_WIDTH-1:0] Output_W_data_2;
    reg [COEFF_WIDTH-1:0] Output_W_data_3;
    reg [COEFF_WIDTH-1:0] Output_W_data_4;


    //==================================================================
    // Status
    //==================================================================

    wire Busy;
    wire Done;
    wire Error;

    wire Load_busy;
    wire Load_error;

    wire Write_busy;
    wire Write_error;

    wire Mode_latched;

    wire [31:0] Src_addr_latched;
    wire [31:0] Dst_addr_latched;


    //==================================================================
    // Testbench Variables
    //==================================================================

    integer test_count;
    integer error_count;

    integer burst;
    integer beat;
    integer core_group;

    integer read_beat_count;
    integer write_beat_count;

    reg [31:0] read_value;

    reg [31:0] expected_araddr;
    reg [31:0] expected_awaddr;

    reg [7:0] source_index;
    reg [7:0] result_index;

    reg [7:0] core_index;


    //==================================================================
    // Functions
    //==================================================================


    //------------------------------------------------------------------
    // Source coefficient:
    //
    //      source[i] = 0x100000 + i
    //------------------------------------------------------------------

    function [COEFF_WIDTH-1:0] MAKE_SOURCE_COEFF;

        input [7:0] Index;

        reg [COEFF_WIDTH-1:0] index_extended;

        begin

            index_extended = {
                {(COEFF_WIDTH - 8){1'b0}},
                Index
            };

            MAKE_SOURCE_COEFF =
                SRC_DATA_BASE +
                index_extended;

        end

    endfunction


    //------------------------------------------------------------------
    // Fake result:
    //
    //      result[i] =
    //          source[i] + RESULT_OFFSET
    //------------------------------------------------------------------

    function [COEFF_WIDTH-1:0] MAKE_RESULT_COEFF;

        input [7:0] Index;

        begin

            MAKE_RESULT_COEFF =
                MAKE_SOURCE_COEFF(Index) +
                RESULT_OFFSET;

        end

    endfunction


    //------------------------------------------------------------------
    // 32-bit system-memory source word.
    //------------------------------------------------------------------

    function [31:0] MAKE_SOURCE_WORD;

        input [7:0] Index;

        begin

            MAKE_SOURCE_WORD = {
                {(32 - COEFF_WIDTH){1'b0}},
                MAKE_SOURCE_COEFF(Index)
            };

        end

    endfunction


    //------------------------------------------------------------------
    // Expected 32-bit result word.
    //------------------------------------------------------------------

    function [31:0] MAKE_RESULT_WORD;

        input [7:0] Index;

        begin

            MAKE_RESULT_WORD = {
                {(32 - COEFF_WIDTH){1'b0}},
                MAKE_RESULT_COEFF(Index)
            };

        end

    endfunction


    //==================================================================
    // DUT
    //==================================================================

    NTT_Acc_Top #(

        .COEFF_WIDTH(COEFF_WIDTH)

    ) DUT (

        // Clock / Reset
        .ACLK                   (ACLK),
        .ARESETn                (ARESETn),


        //==============================================================
        // AXI4-Lite Slave
        //==============================================================

        .S_AXI_AWADDR           (S_AXI_AWADDR),
        .S_AXI_AWVALID          (S_AXI_AWVALID),
        .S_AXI_AWREADY          (S_AXI_AWREADY),

        .S_AXI_WDATA            (S_AXI_WDATA),
        .S_AXI_WSTRB            (S_AXI_WSTRB),
        .S_AXI_WVALID           (S_AXI_WVALID),
        .S_AXI_WREADY           (S_AXI_WREADY),

        .S_AXI_BRESP            (S_AXI_BRESP),
        .S_AXI_BVALID           (S_AXI_BVALID),
        .S_AXI_BREADY           (S_AXI_BREADY),

        .S_AXI_ARADDR           (S_AXI_ARADDR),
        .S_AXI_ARVALID          (S_AXI_ARVALID),
        .S_AXI_ARREADY          (S_AXI_ARREADY),

        .S_AXI_RDATA            (S_AXI_RDATA),
        .S_AXI_RRESP            (S_AXI_RRESP),
        .S_AXI_RVALID           (S_AXI_RVALID),
        .S_AXI_RREADY           (S_AXI_RREADY),


        //==============================================================
        // AXI4 Full Write
        //==============================================================

        .M_AXI_AWADDR           (M_AXI_AWADDR),
        .M_AXI_AWLEN            (M_AXI_AWLEN),
        .M_AXI_AWSIZE           (M_AXI_AWSIZE),
        .M_AXI_AWBURST          (M_AXI_AWBURST),
        .M_AXI_AWVALID          (M_AXI_AWVALID),
        .M_AXI_AWREADY          (M_AXI_AWREADY),

        .M_AXI_WDATA            (M_AXI_WDATA),
        .M_AXI_WSTRB            (M_AXI_WSTRB),
        .M_AXI_WLAST            (M_AXI_WLAST),
        .M_AXI_WVALID           (M_AXI_WVALID),
        .M_AXI_WREADY           (M_AXI_WREADY),

        .M_AXI_BRESP            (M_AXI_BRESP),
        .M_AXI_BVALID           (M_AXI_BVALID),
        .M_AXI_BREADY           (M_AXI_BREADY),


        //==============================================================
        // AXI4 Full Read
        //==============================================================

        .M_AXI_ARADDR           (M_AXI_ARADDR),
        .M_AXI_ARLEN            (M_AXI_ARLEN),
        .M_AXI_ARSIZE           (M_AXI_ARSIZE),
        .M_AXI_ARBURST          (M_AXI_ARBURST),
        .M_AXI_ARVALID          (M_AXI_ARVALID),
        .M_AXI_ARREADY          (M_AXI_ARREADY),

        .M_AXI_RDATA            (M_AXI_RDATA),
        .M_AXI_RRESP            (M_AXI_RRESP),
        .M_AXI_RVALID           (M_AXI_RVALID),
        .M_AXI_RLAST            (M_AXI_RLAST),
        .M_AXI_RREADY           (M_AXI_RREADY),


        //==============================================================
        // Fake Core
        //==============================================================

        .Core_start             (Core_start),
        .Core_fin               (Core_fin),


        // Input Buffer
        .Input_R_addr_1         (Input_R_addr_1),
        .Input_R_addr_2         (Input_R_addr_2),
        .Input_R_addr_3         (Input_R_addr_3),
        .Input_R_addr_4         (Input_R_addr_4),

        .Input_R_data_1         (Input_R_data_1),
        .Input_R_data_2         (Input_R_data_2),
        .Input_R_data_3         (Input_R_data_3),
        .Input_R_data_4         (Input_R_data_4),


        // Output Buffer
        .Output_W_EN_1          (Output_W_EN_1),
        .Output_W_EN_2          (Output_W_EN_2),
        .Output_W_EN_3          (Output_W_EN_3),
        .Output_W_EN_4          (Output_W_EN_4),

        .Output_W_addr_1        (Output_W_addr_1),
        .Output_W_addr_2        (Output_W_addr_2),
        .Output_W_addr_3        (Output_W_addr_3),
        .Output_W_addr_4        (Output_W_addr_4),

        .Output_W_data_1        (Output_W_data_1),
        .Output_W_data_2        (Output_W_data_2),
        .Output_W_data_3        (Output_W_data_3),
        .Output_W_data_4        (Output_W_data_4),


        // Status
        .Busy                   (Busy),
        .Done                   (Done),
        .Error                  (Error),

        .Load_busy              (Load_busy),
        .Load_error             (Load_error),

        .Write_busy             (Write_busy),
        .Write_error            (Write_error),

        .Mode_latched           (Mode_latched),
        .Src_addr_latched       (Src_addr_latched),
        .Dst_addr_latched       (Dst_addr_latched)

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

        $dumpfile("NTT_Acc_Top_tb.vcd");
        $dumpvars(0, tb_NTT_Acc_Top);

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


    task CHECK_COEFF;

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

        end

    endtask


    //==================================================================
    // AXI4-Lite helper: SEND_AW
    //==================================================================

    task automatic SEND_S_AW;

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
    // AXI4-Lite helper: SEND_W
    //==================================================================

    task automatic SEND_S_W;

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
    // AXI4-Lite WRITE
    //==================================================================

    task automatic AXI_LITE_WRITE;

        input [31:0] Address;
        input [31:0] Data;

        begin

            fork

                SEND_S_AW(Address);
                SEND_S_W(Data);

            join


            wait(S_AXI_BVALID === 1'b1);

            #1;


            if(S_AXI_BRESP !== 2'b00) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] AXI-Lite BRESP=%b",
                    S_AXI_BRESP
                );

            end


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
    // AXI4-Lite READ
    //==================================================================

    task automatic AXI_LITE_READ;

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
    // Accept one AXI4 Read Address request
    //==================================================================

    task automatic ACCEPT_READ_AR;

        input [31:0] Expected_addr;

        begin

            wait(M_AXI_ARVALID === 1'b1);

            #1;


            CHECK_32(
                M_AXI_ARADDR,
                Expected_addr,
                "AXI read ARADDR"
            );


            if(M_AXI_ARLEN !== 8'd15) begin

                error_count = error_count + 1;
                $display("[FAIL] ARLEN != 15");

            end


            if(M_AXI_ARSIZE !== 3'b010) begin

                error_count = error_count + 1;
                $display("[FAIL] ARSIZE != 2");

            end


            if(M_AXI_ARBURST !== 2'b01) begin

                error_count = error_count + 1;
                $display("[FAIL] ARBURST != INCR");

            end


            //----------------------------------------------------------
            // One cycle of AR backpressure.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            CHECK_32(
                M_AXI_ARADDR,
                Expected_addr,
                "ARADDR stable during stall"
            );


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

        end

    endtask


    //==================================================================
    // Send one AXI4 read beat
    //==================================================================

    task automatic SEND_READ_BEAT;

        input [31:0] Data;
        input        Last;

        begin

            @(negedge ACLK);

            M_AXI_RDATA  = Data;
            M_AXI_RRESP  = 2'b00;
            M_AXI_RLAST  = Last;
            M_AXI_RVALID = 1'b1;


            @(posedge ACLK);

            while(M_AXI_RREADY !== 1'b1)
                @(posedge ACLK);


            read_beat_count =
                read_beat_count + 1;


            @(negedge ACLK);

            M_AXI_RVALID = 1'b0;
            M_AXI_RLAST  = 1'b0;

        end

    endtask


    //==================================================================
    // Accept one AXI4 Write Address request
    //==================================================================

    task automatic ACCEPT_WRITE_AW;

        input [31:0] Expected_addr;

        begin

            wait(M_AXI_AWVALID === 1'b1);

            #1;


            CHECK_32(
                M_AXI_AWADDR,
                Expected_addr,
                "AXI write AWADDR"
            );


            if(M_AXI_AWLEN !== 8'd15) begin

                error_count = error_count + 1;
                $display("[FAIL] AWLEN != 15");

            end


            if(M_AXI_AWSIZE !== 3'b010) begin

                error_count = error_count + 1;
                $display("[FAIL] AWSIZE != 2");

            end


            if(M_AXI_AWBURST !== 2'b01) begin

                error_count = error_count + 1;
                $display("[FAIL] AWBURST != INCR");

            end


            //----------------------------------------------------------
            // One cycle AW backpressure.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            CHECK_32(
                M_AXI_AWADDR,
                Expected_addr,
                "AWADDR stable during stall"
            );


            @(negedge ACLK);

            M_AXI_AWREADY = 1'b1;


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
    // Accept one AXI4 W beat
    //==================================================================

    task automatic ACCEPT_WRITE_BEAT;

        input [31:0] Expected_data;
        input        Expected_last;

        begin

            wait(M_AXI_WVALID === 1'b1);

            #1;


            CHECK_32(
                M_AXI_WDATA,
                Expected_data,
                "AXI write WDATA"
            );


            CHECK_1(
                M_AXI_WLAST,
                Expected_last,
                "AXI write WLAST"
            );


            if(M_AXI_WSTRB !== 4'b1111) begin

                error_count = error_count + 1;

                $display(
                    "[FAIL] WSTRB != 1111"
                );

            end


            //----------------------------------------------------------
            // Occasionally create one WREADY stall.
            //----------------------------------------------------------

            if((write_beat_count % 7) == 0) begin

                @(posedge ACLK);

                #1;


                CHECK_32(
                    M_AXI_WDATA,
                    Expected_data,
                    "WDATA stable during W stall"
                );

            end


            @(negedge ACLK);

            M_AXI_WREADY = 1'b1;


            @(posedge ACLK);


            write_beat_count =
                write_beat_count + 1;


            @(negedge ACLK);

            M_AXI_WREADY = 1'b0;

        end

    endtask


    //==================================================================
    // Return successful B response
    //==================================================================

    task automatic SEND_WRITE_B_OKAY;

        begin

            //----------------------------------------------------------
            // Delay B for one cycle.
            //----------------------------------------------------------

            @(posedge ACLK);

            #1;


            CHECK_1(
                M_AXI_AWVALID,
                1'b0,
                "No new AW before B"
            );


            @(negedge ACLK);

            M_AXI_BRESP  = 2'b00;
            M_AXI_BVALID = 1'b1;


            @(posedge ACLK);

            while(M_AXI_BREADY !== 1'b1)
                @(posedge ACLK);


            @(negedge ACLK);

            M_AXI_BVALID = 1'b0;

        end

    endtask


    //==================================================================
    // Fake Core
    //
    // Consumes four Input_Buffer coefficients per cycle and writes four
    // transformed coefficients into Output_Buffer.
    //
    // This is NOT NTT functionality.
    //
    // It exists only to verify the surrounding infrastructure.
    //==================================================================

    task automatic RUN_FAKE_CORE;

        begin

            wait(Core_start === 1'b1);

            #1;


            CHECK_1(
                Core_start,
                1'b1,
                "Core_start observed"
            );


            core_index = 8'd0;


            for(
                core_group = 0;
                core_group < 64;
                core_group = core_group + 1
            ) begin


                //------------------------------------------------------
                // Present four Input_Buffer addresses.
                //------------------------------------------------------

                @(negedge ACLK);


                Input_R_addr_1 =
                    core_index;

                Input_R_addr_2 =
                    core_index + 8'd1;

                Input_R_addr_3 =
                    core_index + 8'd2;

                Input_R_addr_4 =
                    core_index + 8'd3;


                //------------------------------------------------------
                // Allow asynchronous reads to settle.
                //------------------------------------------------------

                #1;


                //------------------------------------------------------
                // Verify data actually loaded through AXI read path.
                //------------------------------------------------------

                CHECK_COEFF(
                    Input_R_data_1,
                    MAKE_SOURCE_COEFF(core_index),
                    "Fake core input lane 1"
                );

                CHECK_COEFF(
                    Input_R_data_2,
                    MAKE_SOURCE_COEFF(core_index + 8'd1),
                    "Fake core input lane 2"
                );

                CHECK_COEFF(
                    Input_R_data_3,
                    MAKE_SOURCE_COEFF(core_index + 8'd2),
                    "Fake core input lane 3"
                );

                CHECK_COEFF(
                    Input_R_data_4,
                    MAKE_SOURCE_COEFF(core_index + 8'd3),
                    "Fake core input lane 4"
                );


                //------------------------------------------------------
                // Fake computation:
                //
                // output = input + RESULT_OFFSET
                //------------------------------------------------------

                Output_W_EN_1 = 1'b1;
                Output_W_EN_2 = 1'b1;
                Output_W_EN_3 = 1'b1;
                Output_W_EN_4 = 1'b1;


                Output_W_addr_1 =
                    core_index;

                Output_W_addr_2 =
                    core_index + 8'd1;

                Output_W_addr_3 =
                    core_index + 8'd2;

                Output_W_addr_4 =
                    core_index + 8'd3;


                Output_W_data_1 =
                    Input_R_data_1 +
                    RESULT_OFFSET;

                Output_W_data_2 =
                    Input_R_data_2 +
                    RESULT_OFFSET;

                Output_W_data_3 =
                    Input_R_data_3 +
                    RESULT_OFFSET;

                Output_W_data_4 =
                    Input_R_data_4 +
                    RESULT_OFFSET;


                //------------------------------------------------------
                // Output_Buffer captures all four values here.
                //------------------------------------------------------

                @(posedge ACLK);

                #1;


                core_index =
                    core_index + 8'd4;

            end


            //----------------------------------------------------------
            // Stop output writes.
            //----------------------------------------------------------

            @(negedge ACLK);


            Output_W_EN_1 = 1'b0;
            Output_W_EN_2 = 1'b0;
            Output_W_EN_3 = 1'b0;
            Output_W_EN_4 = 1'b0;


            //----------------------------------------------------------
            // Tell controller fake core has completed.
            //----------------------------------------------------------

            Core_fin = 1'b1;


            @(posedge ACLK);

            #1;


            @(negedge ACLK);

            Core_fin = 1'b0;

        end

    endtask


    //==================================================================
    // MAIN
    //==================================================================

    initial begin


        //==============================================================
        // Initialization
        //==============================================================

        test_count  = 0;
        error_count = 0;

        read_beat_count  = 0;
        write_beat_count = 0;


        ARESETn = 1'b0;


        //--------------------------------------------------------------
        // AXI4-Lite
        //--------------------------------------------------------------

        S_AXI_AWADDR  = 32'b0;
        S_AXI_AWVALID = 1'b0;

        S_AXI_WDATA   = 32'b0;
        S_AXI_WSTRB   = 4'b0;
        S_AXI_WVALID  = 1'b0;

        S_AXI_BREADY  = 1'b0;

        S_AXI_ARADDR  = 32'b0;
        S_AXI_ARVALID = 1'b0;

        S_AXI_RREADY  = 1'b0;


        //--------------------------------------------------------------
        // AXI4 memory slave
        //--------------------------------------------------------------

        M_AXI_AWREADY = 1'b0;
        M_AXI_WREADY  = 1'b0;

        M_AXI_BRESP   = 2'b00;
        M_AXI_BVALID  = 1'b0;

        M_AXI_ARREADY = 1'b0;

        M_AXI_RDATA   = 32'b0;
        M_AXI_RRESP   = 2'b00;
        M_AXI_RVALID  = 1'b0;
        M_AXI_RLAST   = 1'b0;


        //--------------------------------------------------------------
        // Fake core
        //--------------------------------------------------------------

        Core_fin = 1'b0;


        Input_R_addr_1 = 8'd0;
        Input_R_addr_2 = 8'd0;
        Input_R_addr_3 = 8'd0;
        Input_R_addr_4 = 8'd0;


        Output_W_EN_1 = 1'b0;
        Output_W_EN_2 = 1'b0;
        Output_W_EN_3 = 1'b0;
        Output_W_EN_4 = 1'b0;


        Output_W_addr_1 = 8'd0;
        Output_W_addr_2 = 8'd0;
        Output_W_addr_3 = 8'd0;
        Output_W_addr_4 = 8'd0;


        Output_W_data_1 = {COEFF_WIDTH{1'b0}};
        Output_W_data_2 = {COEFF_WIDTH{1'b0}};
        Output_W_data_3 = {COEFF_WIDTH{1'b0}};
        Output_W_data_4 = {COEFF_WIDTH{1'b0}};


        source_index = 8'd0;
        result_index = 8'd0;

        core_index = 8'd0;


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
            "Reset accelerator Error"
        );


        CHECK_1(
            Load_busy,
            1'b0,
            "Reset loader Busy"
        );


        CHECK_1(
            Write_busy,
            1'b0,
            "Reset writer Busy"
        );


        //==============================================================
        // TEST 2: CPU PROGRAMS ACCELERATOR
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 2: AXI-LITE PROGRAMMING");
        $display("================================================");


        AXI_LITE_WRITE(
            ADDR_SRC_ADDR,
            SRC_BASE_ADDR
        );


        AXI_LITE_WRITE(
            ADDR_DST_ADDR,
            DST_BASE_ADDR
        );


        //--------------------------------------------------------------
        // CONTROL:
        //
        // bit 1 = MODE  = 1
        // bit 0 = START = 1
        //--------------------------------------------------------------

        AXI_LITE_WRITE(
            ADDR_CONTROL,
            32'h0000_0003
        );


        CHECK_1(
            Busy,
            1'b1,
            "Accelerator starts"
        );


        CHECK_1(
            Mode_latched,
            1'b1,
            "Mode latched"
        );


        CHECK_32(
            Src_addr_latched,
            SRC_BASE_ADDR,
            "Source address latched"
        );


        CHECK_32(
            Dst_addr_latched,
            DST_BASE_ADDR,
            "Destination address latched"
        );


        //==============================================================
        // TEST 3: AXI4 READ 256 COEFFICIENTS
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 3: AXI4 READ PATH");
        $display("================================================");


        expected_araddr = SRC_BASE_ADDR;
        source_index    = 8'd0;


        for(
            burst = 0;
            burst < 16;
            burst = burst + 1
        ) begin


            ACCEPT_READ_AR(
                expected_araddr
            );


            //----------------------------------------------------------
            // After first burst, CPU reprograms SRC/DST.
            //
            // Current transaction MUST continue using the original
            // latched addresses.
            //----------------------------------------------------------

            if(burst == 0) begin

                AXI_LITE_WRITE(
                    ADDR_SRC_ADDR,
                    NEXT_SRC_ADDR
                );


                AXI_LITE_WRITE(
                    ADDR_DST_ADDR,
                    NEXT_DST_ADDR
                );


                CHECK_32(
                    Src_addr_latched,
                    SRC_BASE_ADDR,
                    "Current SRC snapshot unchanged"
                );


                CHECK_32(
                    Dst_addr_latched,
                    DST_BASE_ADDR,
                    "Current DST snapshot unchanged"
                );

            end


            //----------------------------------------------------------
            // Return 16 AXI R beats.
            //----------------------------------------------------------

            for(
                beat = 0;
                beat < 16;
                beat = beat + 1
            ) begin


                SEND_READ_BEAT(
                    MAKE_SOURCE_WORD(source_index),
                    (beat == 15)
                );


                source_index =
                    source_index + 8'd1;

            end


            expected_araddr =
                expected_araddr +
                32'h0000_0040;

        end


        CHECK_1(
            Load_error,
            1'b0,
            "Read loader completed without error"
        );


        if(read_beat_count !== 256) begin

            error_count = error_count + 1;

            $display(
                "[FAIL] Expected 256 read beats, actual=%0d",
                read_beat_count
            );

        end

        else begin

            $display(
                "[PASS] AXI read beats = 256"
            );

        end


        //==============================================================
        // TEST 4: FAKE COMPUTE CORE
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 4: FAKE CORE");
        $display("================================================");


        RUN_FAKE_CORE();


        //--------------------------------------------------------------
        // Accelerator still running.
        //--------------------------------------------------------------

        CHECK_1(
            Busy,
            1'b1,
            "Accelerator remains Busy after Core_fin"
        );


        //==============================================================
        // TEST 5: AXI4 WRITEBACK
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 5: AXI4 WRITE PATH");
        $display("================================================");


        expected_awaddr = DST_BASE_ADDR;
        result_index    = 8'd0;


        for(
            burst = 0;
            burst < 16;
            burst = burst + 1
        ) begin


            //----------------------------------------------------------
            // This is the critical transaction-snapshot test:
            //
            // CPU changed DST_ADDR earlier, but current AXI write must
            // still use DST_BASE_ADDR.
            //----------------------------------------------------------

            ACCEPT_WRITE_AW(
                expected_awaddr
            );


            //----------------------------------------------------------
            // Receive 16 output coefficients.
            //----------------------------------------------------------

            for(
                beat = 0;
                beat < 16;
                beat = beat + 1
            ) begin


                ACCEPT_WRITE_BEAT(
                    MAKE_RESULT_WORD(result_index),
                    (beat == 15)
                );


                result_index =
                    result_index + 8'd1;

            end


            //----------------------------------------------------------
            // Complete this write burst.
            //----------------------------------------------------------

            SEND_WRITE_B_OKAY();


            expected_awaddr =
                expected_awaddr +
                32'h0000_0040;

        end


        //==============================================================
        // TEST 6: COMPLETE TRANSACTION
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 6: TRANSACTION COMPLETION");
        $display("================================================");


        //--------------------------------------------------------------
        // The AXI Write Writer has already accepted the final B
        // response.
        //
        // At this point:
        //
        //      Writer:
        //          Write_busy = 0
        //          write_done_in = 1
        //
        // But Acc_Controller has NOT consumed write_done_in yet,
        // because both modules are clocked sequential logic.
        //
        // Therefore the accelerator itself should still be:
        //
        //      Busy = 1
        //      Done = 0
        //
        // until the NEXT rising edge.
        //--------------------------------------------------------------

        #1;


        CHECK_1(
            Write_error,
            1'b0,
            "Write path completed without error"
        );


        CHECK_1(
            Write_busy,
            1'b0,
            "AXI writer is idle after final B"
        );


        if(write_beat_count !== 256) begin

            error_count = error_count + 1;

            $display(
                "[FAIL] Expected 256 write beats, actual=%0d",
                write_beat_count
            );

        end
        else begin

            $display(
                "[PASS] AXI write beats = 256"
            );

        end


        //--------------------------------------------------------------
        // Important sequential-boundary check.
        //
        // Writer has completed, but Controller has not consumed
        // write_done_in yet.
        //--------------------------------------------------------------

        CHECK_1(
            Busy,
            1'b1,
            "Controller still Busy before consuming Write_done"
        );


        CHECK_1(
            Done,
            1'b0,
            "Controller Done still low before consuming Write_done"
        );


        //--------------------------------------------------------------
        // One more rising edge:
        //
        // Acc_Controller now sees the previous cycle's
        // write_done_in = 1.
        //
        // STATE_WRITE_OUTPUT:
        //      Write_done = 1
        //          ↓
        //      Busy <= 0
        //      Done <= 1
        //      state <= IDLE
        //--------------------------------------------------------------

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
            "Accelerator Done asserted after Write_done"
        );


        CHECK_1(
            Error,
            1'b0,
            "Controller Error remains low"
        );


        //==============================================================
        // TEST 7: CPU READS STATUS
        //==============================================================

        $display("");
        $display("================================================");
        $display("TEST 7: SOFTWARE STATUS");
        $display("================================================");


        AXI_LITE_READ(
            ADDR_STATUS,
            read_value
        );


        //--------------------------------------------------------------
        // STATUS:
        //
        // Error = 0
        // Done  = 1
        // Busy  = 0
        //
        // => 0b010 = 0x2
        //--------------------------------------------------------------

        CHECK_32(
            read_value,
            32'h0000_0002,
            "STATUS reports Done"
        );


        //==============================================================
        // TEST 8: REGISTER SNAPSHOT SEMANTICS
        //==============================================================

        //--------------------------------------------------------------
        // Raw registers were changed during operation.
        //
        // Read them back now.
        //--------------------------------------------------------------

        AXI_LITE_READ(
            ADDR_SRC_ADDR,
            read_value
        );


        CHECK_32(
            read_value,
            NEXT_SRC_ADDR,
            "CPU-visible SRC contains next value"
        );


        AXI_LITE_READ(
            ADDR_DST_ADDR,
            read_value
        );


        CHECK_32(
            read_value,
            NEXT_DST_ADDR,
            "CPU-visible DST contains next value"
        );


        //--------------------------------------------------------------
        // But the completed transaction used:
        //
        // SRC_BASE_ADDR
        // DST_BASE_ADDR
        //
        // as verified by every ARADDR / AWADDR above.
        //--------------------------------------------------------------


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
            $display(
                "ALL FULL NTT ACCELERATOR INTEGRATION TESTS PASSED"
            );

        end

        else begin

            $display("");
            $display(
                "FULL NTT ACCELERATOR INTEGRATION TEST FAILED"
            );

        end


        #20;

        $finish;

    end


endmodule
