class AXIL_Channel_Stall_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Channel_Stall_Test)
    virtual AXIL_if vif;
    AXIL_Protocol_Checker protocol_checker;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Channel_Stall_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        uvm_config_int::set(this, "env.agent", "is_active", UVM_PASSIVE);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Channel_Stall_Test cannot get virtual interface")
        end
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        drive_idle();
        wait(vif.ARESETn == 1'b1);
        @(negedge vif.ACLK);
        `uvm_info("CHANNEL_STALL_TEST",
            "Starting AXI-Lite AW/W/AR request-side stall test", UVM_MEDIUM)
        write_overlap_case(1, 32'h1111_0001, 32'h2222_0001);
        write_overlap_case(2, 32'h1111_0002, 32'h2222_0002);
        write_overlap_case(3, 32'h1111_0003, 32'h2222_0003);
        read_overlap_case(1);
        read_overlap_case(2);
        read_overlap_case(3);
        repeat(5)
            @(posedge vif.ACLK);
        protocol_checker = env.agent.get_protocol_checker();
        if(protocol_checker == null)
            `uvm_fatal("CHANNEL_STALL_TEST", "AXIL protocol checker handle is null")
        check_protocol_counts();
        protocol_checker.report_summary("AXIL_Channel_Stall_Test");
        `uvm_info("CHANNEL_STALL_TEST",
            "AXI-Lite AW/W/AR request-side stall test completed", UVM_MEDIUM)
        phase.drop_objection(this);
    endtask
    task drive_idle();
        vif.S_AXI_AWADDR = '0;
        vif.S_AXI_AWVALID = 1'b0;
        vif.S_AXI_WDATA = '0;
        vif.S_AXI_WSTRB = '0;
        vif.S_AXI_WVALID = 1'b0;
        vif.S_AXI_BREADY = 1'b0;
        vif.S_AXI_ARADDR = '0;
        vif.S_AXI_ARVALID = 1'b0;
        vif.S_AXI_RREADY = 1'b0;
    endtask
    task write_overlap_case(
        int unsigned request_stall_cycles,
        bit [31:0] first_data,
        bit [31:0] second_data
    );
        if(request_stall_cycles < 1)
            `uvm_fatal("CHANNEL_STALL_TEST", "request_stall_cycles must be >= 1")
        drive_write_request(ADDR_SRC_ADDR, first_data);
        wait(vif.S_AXI_BVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_AWADDR = ADDR_DST_ADDR;
        vif.S_AXI_AWVALID = 1'b1;
        vif.S_AXI_WDATA = second_data;
        vif.S_AXI_WSTRB = 4'hF;
        vif.S_AXI_WVALID = 1'b1;
        vif.S_AXI_BREADY = 1'b0;
        repeat(request_stall_cycles - 1) begin
            @(posedge vif.ACLK);
            if(vif.S_AXI_AWREADY || vif.S_AXI_WREADY)
                `uvm_fatal("CHANNEL_STALL_TEST",
                    "AWREADY/WREADY asserted while prior B response was pending")
            @(negedge vif.ACLK);
        end
        vif.S_AXI_BREADY = 1'b1;
        @(posedge vif.ACLK);
        if(vif.S_AXI_AWREADY || vif.S_AXI_WREADY)
            `uvm_fatal("CHANNEL_STALL_TEST",
                "AW/W request was accepted on the prior B handshake cycle")
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
        @(posedge vif.ACLK);
        if(!(vif.S_AXI_AWREADY && vif.S_AXI_WREADY))
            `uvm_fatal("CHANNEL_STALL_TEST",
                "AWREADY/WREADY did not reopen after prior B response completed")
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
        vif.S_AXI_WVALID = 1'b0;
        accept_b_response();
    endtask
    task drive_write_request(
        bit [31:0] addr,
        bit [31:0] data
    );
        @(negedge vif.ACLK);
        vif.S_AXI_AWADDR = addr;
        vif.S_AXI_AWVALID = 1'b1;
        vif.S_AXI_WDATA = data;
        vif.S_AXI_WSTRB = 4'hF;
        vif.S_AXI_WVALID = 1'b1;
        vif.S_AXI_BREADY = 1'b0;
        @(posedge vif.ACLK);
        if(!(vif.S_AXI_AWREADY && vif.S_AXI_WREADY))
            `uvm_fatal("CHANNEL_STALL_TEST",
                "Initial AW/W request was not accepted while the slave was idle")
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
        vif.S_AXI_WVALID = 1'b0;
    endtask
    task accept_b_response();
        wait(vif.S_AXI_BVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_BVALID)
            `uvm_fatal("CHANNEL_STALL_TEST", "BVALID missing on expected B handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
    endtask
    task read_overlap_case(int unsigned request_stall_cycles);
        if(request_stall_cycles < 1)
            `uvm_fatal("CHANNEL_STALL_TEST", "request_stall_cycles must be >= 1")
        drive_read_request(ADDR_SRC_ADDR);
        wait(vif.S_AXI_RVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_ARADDR = ADDR_DST_ADDR;
        vif.S_AXI_ARVALID = 1'b1;
        vif.S_AXI_RREADY = 1'b0;
        repeat(request_stall_cycles - 1) begin
            @(posedge vif.ACLK);
            if(vif.S_AXI_ARREADY)
                `uvm_fatal("CHANNEL_STALL_TEST",
                    "ARREADY asserted while prior R response was pending")
            @(negedge vif.ACLK);
        end
        vif.S_AXI_RREADY = 1'b1;
        @(posedge vif.ACLK);
        if(vif.S_AXI_ARREADY)
            `uvm_fatal("CHANNEL_STALL_TEST",
                "AR request was accepted on the prior R handshake cycle")
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_ARREADY)
            `uvm_fatal("CHANNEL_STALL_TEST",
                "ARREADY did not reopen after prior R response completed")
        @(negedge vif.ACLK);
        vif.S_AXI_ARVALID = 1'b0;
        accept_r_response();
    endtask
    task drive_read_request(bit [31:0] addr);
        @(negedge vif.ACLK);
        vif.S_AXI_ARADDR = addr;
        vif.S_AXI_ARVALID = 1'b1;
        vif.S_AXI_RREADY = 1'b0;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_ARREADY)
            `uvm_fatal("CHANNEL_STALL_TEST",
                "Initial AR request was not accepted while the slave was idle")
        @(negedge vif.ACLK);
        vif.S_AXI_ARVALID = 1'b0;
    endtask
    task accept_r_response();
        wait(vif.S_AXI_RVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_RVALID)
            `uvm_fatal("CHANNEL_STALL_TEST", "RVALID missing on expected R handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
    endtask
    function void check_protocol_counts();
        if(protocol_checker.aw_handshakes != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 AW handshakes, observed %0d",
                protocol_checker.aw_handshakes))
        if(protocol_checker.w_handshakes != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 W handshakes, observed %0d",
                protocol_checker.w_handshakes))
        if(protocol_checker.b_handshakes != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 B handshakes, observed %0d",
                protocol_checker.b_handshakes))
        if(protocol_checker.ar_handshakes != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 AR handshakes, observed %0d",
                protocol_checker.ar_handshakes))
        if(protocol_checker.r_handshakes != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 R handshakes, observed %0d",
                protocol_checker.r_handshakes))
        if(protocol_checker.aw_stall_cycles != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 AW stall cycles, observed %0d",
                protocol_checker.aw_stall_cycles))
        if(protocol_checker.w_stall_cycles != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 W stall cycles, observed %0d",
                protocol_checker.w_stall_cycles))
        if(protocol_checker.ar_stall_cycles != 6)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 6 AR stall cycles, observed %0d",
                protocol_checker.ar_stall_cycles))
        if(protocol_checker.b_stall_cycles != 3)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 3 B stall cycles, observed %0d",
                protocol_checker.b_stall_cycles))
        // The three first read responses are intentionally stalled for
        // 1, 2, and 3 cycles. Each second read response also sees one
        // cycle with RVALID high before accept_r_response() raises RREADY.
        // Total expected R stalls = (1 + 2 + 3) + (1 + 1 + 1) = 9.
        if(protocol_checker.r_stall_cycles != 9)
            `uvm_error("CHANNEL_STALL_TEST", $sformatf(
                "Expected 9 R stall cycles, observed %0d",
                protocol_checker.r_stall_cycles))
    endfunction
endclass
