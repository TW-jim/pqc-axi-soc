`timescale 1ns / 1ps
// !!!AI-GENERATED!!!
module tb_Input_Buffer_Banked;

    parameter COEFF_WIDTH = 23;
    parameter DEPTH       = 256;
    parameter ADDR_WIDTH  = 8;


    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------

    reg ACLK;

    reg                        W_EN;
    reg  [ADDR_WIDTH-1:0]      W_addr;
    reg  [COEFF_WIDTH-1:0]     W_data;

    reg  [ADDR_WIDTH-1:0]      R_addr_1;
    reg  [ADDR_WIDTH-1:0]      R_addr_2;
    reg  [ADDR_WIDTH-1:0]      R_addr_3;
    reg  [ADDR_WIDTH-1:0]      R_addr_4;

    wire [COEFF_WIDTH-1:0]     R_data_1;
    wire [COEFF_WIDTH-1:0]     R_data_2;
    wire [COEFF_WIDTH-1:0]     R_data_3;
    wire [COEFF_WIDTH-1:0]     R_data_4;


    // --------------------------------------------------------
    // Reference memory
    // --------------------------------------------------------

    reg [COEFF_WIDTH-1:0] reference_mem [0:DEPTH-1];


    integer i;
    integer g;

    integer checks;
    integer errors;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    Input_Buffer #(
        .COEFF_WIDTH (COEFF_WIDTH),
        .DEPTH       (DEPTH),
        .ADDR_WIDTH  (ADDR_WIDTH)
    ) dut (
        .ACLK     (ACLK),

        .W_EN     (W_EN),
        .W_addr   (W_addr),
        .W_data   (W_data),

        .R_addr_1 (R_addr_1),
        .R_addr_2 (R_addr_2),
        .R_addr_3 (R_addr_3),
        .R_addr_4 (R_addr_4),

        .R_data_1 (R_data_1),
        .R_data_2 (R_data_2),
        .R_data_3 (R_data_3),
        .R_data_4 (R_data_4)
    );


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin

        ACLK = 1'b0;

        forever begin
            #5 ACLK = ~ACLK;
        end

    end


    // --------------------------------------------------------
    // Write one logical coefficient
    // --------------------------------------------------------

    task write_coeff;

        input integer addr;
        input [COEFF_WIDTH-1:0] data;

        begin

            @(negedge ACLK);

            W_EN   = 1'b1;
            W_addr = addr[ADDR_WIDTH-1:0];
            W_data = data;

            @(negedge ACLK);

            W_EN   = 1'b0;
            W_addr = {ADDR_WIDTH{1'b0}};
            W_data = {COEFF_WIDTH{1'b0}};

        end

    endtask


    // --------------------------------------------------------
    // Check one four-way read group
    // --------------------------------------------------------

    task check_group;

        input integer addr_1;
        input integer addr_2;
        input integer addr_3;
        input integer addr_4;

        begin

            @(negedge ACLK);

            R_addr_1 = addr_1[ADDR_WIDTH-1:0];
            R_addr_2 = addr_2[ADDR_WIDTH-1:0];
            R_addr_3 = addr_3[ADDR_WIDTH-1:0];
            R_addr_4 = addr_4[ADDR_WIDTH-1:0];

            #1;


            checks = checks + 1;

            if (R_data_1 !== reference_mem[addr_1]) begin

                $display(
                    "ERROR R1: addr=%0d expected=%h actual=%h",
                    addr_1,
                    reference_mem[addr_1],
                    R_data_1
                );

                errors = errors + 1;

            end


            checks = checks + 1;

            if (R_data_2 !== reference_mem[addr_2]) begin

                $display(
                    "ERROR R2: addr=%0d expected=%h actual=%h",
                    addr_2,
                    reference_mem[addr_2],
                    R_data_2
                );

                errors = errors + 1;

            end


            checks = checks + 1;

            if (R_data_3 !== reference_mem[addr_3]) begin

                $display(
                    "ERROR R3: addr=%0d expected=%h actual=%h",
                    addr_3,
                    reference_mem[addr_3],
                    R_data_3
                );

                errors = errors + 1;

            end


            checks = checks + 1;

            if (R_data_4 !== reference_mem[addr_4]) begin

                $display(
                    "ERROR R4: addr=%0d expected=%h actual=%h",
                    addr_4,
                    reference_mem[addr_4],
                    R_data_4
                );

                errors = errors + 1;

            end

        end

    endtask


    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        W_EN   = 1'b0;
        W_addr = {ADDR_WIDTH{1'b0}};
        W_data = {COEFF_WIDTH{1'b0}};

        R_addr_1 = {ADDR_WIDTH{1'b0}};
        R_addr_2 = {ADDR_WIDTH{1'b0}};
        R_addr_3 = {ADDR_WIDTH{1'b0}};
        R_addr_4 = {ADDR_WIDTH{1'b0}};

        checks = 0;
        errors = 0;


        // ----------------------------------------------------
        // Fill all 256 logical locations.
        // ----------------------------------------------------

        for (i = 0; i < DEPTH; i = i + 1) begin

            reference_mem[i] =
                (i * 23'd97) + 23'd13;

            write_coeff(
                i,
                reference_mem[i]
            );

        end


        // ----------------------------------------------------
        // NTT access pattern
        //
        //   g
        //   g + 64
        //   g + 128
        //   g + 192
        // ----------------------------------------------------

        $display("");
        $display("Checking NTT access pattern...");

        for (g = 0; g < 64; g = g + 1) begin

            check_group(
                g,
                g + 64,
                g + 128,
                g + 192
            );

        end


        // ----------------------------------------------------
        // INTT access pattern
        //
        //   4g
        //   4g + 2
        //   4g + 1
        //   4g + 3
        // ----------------------------------------------------

        $display("");
        $display("Checking INTT access pattern...");

        for (g = 0; g < 64; g = g + 1) begin

            check_group(
                (4 * g),
                (4 * g) + 2,
                (4 * g) + 1,
                (4 * g) + 3
            );

        end


        // ----------------------------------------------------
        // Rewrite selected locations.
        //
        // This confirms that logical writes still reach the
        // correct physical bank and row after banking.
        // ----------------------------------------------------

        reference_mem[5]   = 23'h012345;
        reference_mem[69]  = 23'h023456;
        reference_mem[133] = 23'h034567;
        reference_mem[197] = 23'h045678;

        write_coeff(5,   reference_mem[5]);
        write_coeff(69,  reference_mem[69]);
        write_coeff(133, reference_mem[133]);
        write_coeff(197, reference_mem[197]);


        check_group(
            5,
            69,
            133,
            197
        );


        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("Banked Input Buffer Test Summary");
        $display("========================================");

        $display("Checks : %0d", checks);
        $display("Errors : %0d", errors);


        if (errors == 0) begin

            $display("");
            $display("ALL BANKED INPUT BUFFER TESTS PASSED");

        end
        else begin

            $display("");
            $display("BANKED INPUT BUFFER TEST FAILED");

        end


        $display("========================================");

        $finish;

    end


endmodule
