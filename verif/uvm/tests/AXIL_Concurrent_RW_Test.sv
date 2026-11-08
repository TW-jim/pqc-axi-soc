class AXIL_Concurrent_RW_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Concurrent_RW_Test)
    virtual AXIL_if vif;
    AXIL_Protocol_Checker protocol_checker;
    localparam bit [31:0] ADDR_STATUS = 32'h0000_0004;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Concurrent_RW_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        uvm_config_int::set(this, "env.agent", "is_active", UVM_PASSIVE);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Concurrent_RW_Test cannot get virtual interface")
        end
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        drive_idle();
        wait(vif.ARESETn == 1'b1);
        @(negedge vif.ACLK);
        `uvm_info("CONCURRENT_RW_TEST",
            "Starting concurrent AXI-Lite read/write test", UVM_MEDIUM)
        read_while_b_stalled();
        write_while_r_stalled();
        repeat(5)
            @(posedge vif.ACLK);
        protocol_checker = env.agent.get_protocol_checker();
        if(protocol_checker == null)
            `uvm_fatal("CONCURRENT_RW_TEST", "AXIL protocol checker handle is null")
        check_protocol_counts();
        protocol_checker.report_summary("AXIL_Concurrent_RW_Test");
        `uvm_info("CONCURRENT_RW_TEST",
            "Concurrent AXI-Lite read/write test completed", UVM_MEDIUM)
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
        @(posedge vif.ACLK);
        if(!(vif.S_AXI_AWREADY && vif.S_AXI_WREADY))
            `uvm_fatal("CONCURRENT_RW_TEST", "Expected simultaneous AW/W handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
        vif.S_AXI_WVALID = 1'b0;
    endtask
    task drive_read_request(bit [31:0] addr);
        @(negedge vif.ACLK);
        vif.S_AXI_ARADDR = addr;
        vif.S_AXI_ARVALID = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_ARREADY) `uvm_fatal("CONCURRENT_RW_TEST", "Expected AR handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_ARVALID = 1'b0;
    endtask
    task read_while_b_stalled();
        drive_write_request(ADDR_SRC_ADDR, 32'h1357_2468);
        wait(vif.S_AXI_BVALID == 1'b1);
        vif.S_AXI_BREADY = 1'b0;
        drive_read_request(ADDR_STATUS);
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!(vif.S_AXI_RVALID && vif.S_AXI_RREADY))
            `uvm_fatal("CONCURRENT_RW_TEST", "Expected R handshake while B was stalled")
        if(!(vif.S_AXI_BVALID && !vif.S_AXI_BREADY))
            `uvm_fatal("CONCURRENT_RW_TEST",
                "B response was not still stalled during concurrent R handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
        vif.S_AXI_BREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_BVALID)
            `uvm_fatal("CONCURRENT_RW_TEST", "Expected B handshake after concurrent read")
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
    endtask
    task write_while_r_stalled();
        drive_read_request(ADDR_STATUS);
        wait(vif.S_AXI_RVALID == 1'b1);
        vif.S_AXI_RREADY = 1'b0;
        drive_write_request(ADDR_DST_ADDR, 32'hCAFE_BABE);
        wait(vif.S_AXI_BVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!(vif.S_AXI_BVALID && vif.S_AXI_BREADY))
            `uvm_fatal("CONCURRENT_RW_TEST", "Expected B handshake while R was stalled")
        if(!(vif.S_AXI_RVALID && !vif.S_AXI_RREADY))
            `uvm_fatal("CONCURRENT_RW_TEST",
                "R response was not still stalled during concurrent B handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
        vif.S_AXI_RREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_RVALID)
            `uvm_fatal("CONCURRENT_RW_TEST", "Expected R handshake after concurrent write")
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
    endtask
    function void check_protocol_counts();
        if(protocol_checker.aw_handshakes != 2)
            `uvm_error("CONCURRENT_RW_TEST", $sformatf(
                "Expected 2 AW handshakes, observed %0d",
                protocol_checker.aw_handshakes))
        if(protocol_checker.w_handshakes != 2)
            `uvm_error("CONCURRENT_RW_TEST", $sformatf(
                "Expected 2 W handshakes, observed %0d",
                protocol_checker.w_handshakes))
        if(protocol_checker.b_handshakes != 2)
            `uvm_error("CONCURRENT_RW_TEST", $sformatf(
                "Expected 2 B handshakes, observed %0d",
                protocol_checker.b_handshakes))
        if(protocol_checker.ar_handshakes != 2)
            `uvm_error("CONCURRENT_RW_TEST", $sformatf(
                "Expected 2 AR handshakes, observed %0d",
                protocol_checker.ar_handshakes))
        if(protocol_checker.r_handshakes != 2)
            `uvm_error("CONCURRENT_RW_TEST", $sformatf(
                "Expected 2 R handshakes, observed %0d",
                protocol_checker.r_handshakes))
        if(protocol_checker.b_stall_cycles == 0)
            `uvm_error("CONCURRENT_RW_TEST", "Expected at least one B stall cycle")
        if(protocol_checker.r_stall_cycles == 0)
            `uvm_error("CONCURRENT_RW_TEST", "Expected at least one R stall cycle")
    endfunction
endclass
