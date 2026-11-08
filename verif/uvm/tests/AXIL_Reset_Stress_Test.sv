class AXIL_Reset_Stress_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Reset_Stress_Test)
    virtual AXIL_if vif;
    AXIL_Protocol_Checker protocol_checker;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Reset_Stress_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        uvm_config_int::set(this, "env.agent", "is_active", UVM_PASSIVE);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Reset_Stress_Test cannot get virtual interface")
        end
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        drive_idle();
        vif.tb_reset_req = 1'b0;
        wait(vif.ARESETn == 1'b1);
        @(negedge vif.ACLK);
        `uvm_info("RESET_STRESS_TEST",
            "Starting AXI-Lite reset-under-activity test", UVM_MEDIUM)
        reset_after_aw_only();
        reset_after_w_only();
        reset_during_b_stall();
        reset_during_r_stall();
        repeat(5)
            @(posedge vif.ACLK);
        protocol_checker = env.agent.get_protocol_checker();
        if(protocol_checker == null)
            `uvm_fatal("RESET_STRESS_TEST", "AXIL protocol checker handle is null")
        protocol_checker.report_summary("AXIL_Reset_Stress_Test post-final-reset");
        `uvm_info("RESET_STRESS_TEST",
            "AXI-Lite reset-under-activity test completed", UVM_MEDIUM)
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
    task pulse_reset();
        @(negedge vif.ACLK);
        vif.tb_reset_req = 1'b1;
        drive_idle();
        repeat(2)
            @(posedge vif.ACLK);
        if(vif.ARESETn !== 1'b0) `uvm_fatal("RESET_STRESS_TEST", "ARESETn did not assert")
        if(vif.S_AXI_BVALID !== 1'b0 || vif.S_AXI_RVALID !== 1'b0)
            `uvm_fatal("RESET_STRESS_TEST", "Response VALID remained asserted during reset")
        if(vif.Mode !== 1'b0 || vif.Src_addr !== 32'b0 || vif.Dst_addr !== 32'b0)
            `uvm_fatal("RESET_STRESS_TEST", "DUT register state did not clear during reset")
        @(negedge vif.ACLK);
        vif.tb_reset_req = 1'b0;
        @(posedge vif.ACLK);
        if(vif.ARESETn !== 1'b1) `uvm_fatal("RESET_STRESS_TEST", "ARESETn did not deassert")
        if(!(vif.S_AXI_AWREADY && vif.S_AXI_WREADY && vif.S_AXI_ARREADY))
            `uvm_fatal("RESET_STRESS_TEST", "READY signals did not recover after reset")
        if(vif.S_AXI_BVALID || vif.S_AXI_RVALID)
            `uvm_fatal("RESET_STRESS_TEST", "Response VALID asserted unexpectedly after reset")
    endtask
    task reset_after_aw_only();
        @(negedge vif.ACLK);
        vif.S_AXI_AWADDR = ADDR_SRC_ADDR;
        vif.S_AXI_AWVALID = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_AWREADY) `uvm_fatal("RESET_STRESS_TEST", "AW-only request was not accepted")
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
        if(vif.S_AXI_BVALID) `uvm_fatal("RESET_STRESS_TEST", "BVALID asserted with AW only")
        pulse_reset();
    endtask
    task reset_after_w_only();
        @(negedge vif.ACLK);
        vif.S_AXI_WDATA = 32'h1111_AAAA;
        vif.S_AXI_WSTRB = 4'hF;
        vif.S_AXI_WVALID = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_WREADY) `uvm_fatal("RESET_STRESS_TEST", "W-only request was not accepted")
        @(negedge vif.ACLK);
        vif.S_AXI_WVALID = 1'b0;
        if(vif.S_AXI_BVALID) `uvm_fatal("RESET_STRESS_TEST", "BVALID asserted with W only")
        pulse_reset();
    endtask
    task reset_during_b_stall();
        drive_write_request(ADDR_SRC_ADDR, 32'h89AB_CDEF);
        wait(vif.S_AXI_BVALID == 1'b1);
        if(vif.Src_addr !== 32'h89AB_CDEF)
            `uvm_fatal("RESET_STRESS_TEST", "Write data was not committed before B stall")
        vif.S_AXI_BREADY = 1'b0;
        pulse_reset();
        read_and_accept(ADDR_SRC_ADDR, 32'b0);
    endtask
    task reset_during_r_stall();
        drive_write_request(ADDR_DST_ADDR, 32'h7654_3210);
        accept_b_response();
        drive_read_request(ADDR_DST_ADDR);
        wait(vif.S_AXI_RVALID == 1'b1);
        if(vif.S_AXI_RDATA !== 32'h7654_3210)
            `uvm_fatal("RESET_STRESS_TEST", "Unexpected RDATA before reset")
        vif.S_AXI_RREADY = 1'b0;
        pulse_reset();
        read_and_accept(ADDR_DST_ADDR, 32'b0);
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
            `uvm_fatal("RESET_STRESS_TEST", "Expected simultaneous AW/W handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
        vif.S_AXI_WVALID = 1'b0;
    endtask
    task accept_b_response();
        wait(vif.S_AXI_BVALID == 1'b1);
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_BVALID) `uvm_fatal("RESET_STRESS_TEST", "Expected B handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
    endtask
    task drive_read_request(bit [31:0] addr);
        @(negedge vif.ACLK);
        vif.S_AXI_ARADDR = addr;
        vif.S_AXI_ARVALID = 1'b1;
        vif.S_AXI_RREADY = 1'b0;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_ARREADY) `uvm_fatal("RESET_STRESS_TEST", "Expected AR handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_ARVALID = 1'b0;
    endtask
    task read_and_accept(
        bit [31:0] addr,
        bit [31:0] expected_data
    );
        drive_read_request(addr);
        wait(vif.S_AXI_RVALID == 1'b1);
        if(vif.S_AXI_RDATA !== expected_data)
            `uvm_fatal("RESET_STRESS_TEST", $sformatf(
                "Unexpected readback after reset: addr=0x%08h expected=0x%08h actual=0x%08h",
                addr, expected_data, vif.S_AXI_RDATA))
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b1;
        @(posedge vif.ACLK);
        if(!vif.S_AXI_RVALID) `uvm_fatal("RESET_STRESS_TEST", "Expected R handshake")
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
    endtask
endclass
