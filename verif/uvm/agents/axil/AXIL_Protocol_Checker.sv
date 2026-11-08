class AXIL_Protocol_Checker extends uvm_component;
    `uvm_component_utils(AXIL_Protocol_Checker)
    virtual AXIL_if vif;
    bit aw_hold_active;
    bit [31:0] awaddr_hold;
    bit w_hold_active;
    bit [31:0] wdata_hold;
    bit [3:0] wstrb_hold;
    bit b_hold_active;
    bit [1:0] bresp_hold;
    bit ar_hold_active;
    bit [31:0] araddr_hold;
    bit r_hold_active;
    bit [31:0] rdata_hold;
    bit [1:0] rresp_hold;
    bit aw_seen;
    bit w_seen;
    bit ar_seen;
    longint unsigned aw_handshakes;
    longint unsigned w_handshakes;
    longint unsigned b_handshakes;
    longint unsigned ar_handshakes;
    longint unsigned r_handshakes;
    longint unsigned aw_stall_cycles;
    longint unsigned w_stall_cycles;
    longint unsigned b_stall_cycles;
    longint unsigned ar_stall_cycles;
    longint unsigned r_stall_cycles;
    function new(string name = "AXIL_Protocol_Checker", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Protocol_Checker cannot get virtual interface")
        end
    endfunction
    task run_phase(uvm_phase phase);
        reset_state();
        `uvm_info("AXIL_PROTOCOL", "AXI-Lite protocol checker active", UVM_LOW)
        forever begin
            @(posedge vif.ACLK);
            if(!vif.ARESETn) reset_state();
            else begin
                check_stability();
                check_response_ordering();
                update_statistics();
                update_hold_state();
            end
        end
    endtask
    task reset_state();
        aw_hold_active = 1'b0;
        w_hold_active = 1'b0;
        b_hold_active = 1'b0;
        ar_hold_active = 1'b0;
        r_hold_active = 1'b0;
        aw_seen = 1'b0;
        w_seen = 1'b0;
        ar_seen = 1'b0;
        aw_handshakes = 0;
        w_handshakes = 0;
        b_handshakes = 0;
        ar_handshakes = 0;
        r_handshakes = 0;
        aw_stall_cycles = 0;
        w_stall_cycles = 0;
        b_stall_cycles = 0;
        ar_stall_cycles = 0;
        r_stall_cycles = 0;
    endtask
    task check_stability();
        if(aw_hold_active) begin
            if(!vif.S_AXI_AWVALID)
                `uvm_error("AXIL_PROTOCOL", "AWVALID dropped before AW handshake")
            if(vif.S_AXI_AWADDR != awaddr_hold)
                `uvm_error("AXIL_PROTOCOL", "AWADDR changed while AWVALID was stalled")
        end
        if(w_hold_active) begin
            if(!vif.S_AXI_WVALID)
                `uvm_error("AXIL_PROTOCOL", "WVALID dropped before W handshake")
            if(vif.S_AXI_WDATA != wdata_hold)
                `uvm_error("AXIL_PROTOCOL", "WDATA changed while WVALID was stalled")
            if(vif.S_AXI_WSTRB != wstrb_hold)
                `uvm_error("AXIL_PROTOCOL", "WSTRB changed while WVALID was stalled")
        end
        if(b_hold_active) begin
            if(!vif.S_AXI_BVALID)
                `uvm_error("AXIL_PROTOCOL", "BVALID dropped before B handshake")
            if(vif.S_AXI_BRESP != bresp_hold)
                `uvm_error("AXIL_PROTOCOL", "BRESP changed while BVALID was stalled")
        end
        if(ar_hold_active) begin
            if(!vif.S_AXI_ARVALID)
                `uvm_error("AXIL_PROTOCOL", "ARVALID dropped before AR handshake")
            if(vif.S_AXI_ARADDR != araddr_hold)
                `uvm_error("AXIL_PROTOCOL", "ARADDR changed while ARVALID was stalled")
        end
        if(r_hold_active) begin
            if(!vif.S_AXI_RVALID)
                `uvm_error("AXIL_PROTOCOL", "RVALID dropped before R handshake")
            if(vif.S_AXI_RDATA != rdata_hold)
                `uvm_error("AXIL_PROTOCOL", "RDATA changed while RVALID was stalled")
            if(vif.S_AXI_RRESP != rresp_hold)
                `uvm_error("AXIL_PROTOCOL", "RRESP changed while RVALID was stalled")
        end
    endtask
    task check_response_ordering();
        if(vif.S_AXI_AWVALID && vif.S_AXI_AWREADY) begin
            if(aw_seen)
                `uvm_error("AXIL_PROTOCOL", "Second AW handshake before prior B response")
            aw_seen = 1'b1;
        end
        if(vif.S_AXI_WVALID && vif.S_AXI_WREADY) begin
            if(w_seen)
                `uvm_error("AXIL_PROTOCOL", "Second W handshake before prior B response")
            w_seen = 1'b1;
        end
        if(vif.S_AXI_BVALID && !(aw_seen && w_seen)) begin
            `uvm_error("AXIL_PROTOCOL",
                "BVALID asserted before both AW and W handshakes were observed")
        end
        if(vif.S_AXI_BVALID && vif.S_AXI_BREADY) begin
            aw_seen = 1'b0;
            w_seen = 1'b0;
        end
        if(vif.S_AXI_ARVALID && vif.S_AXI_ARREADY) begin
            if(ar_seen)
                `uvm_error("AXIL_PROTOCOL", "Second AR handshake before prior R response")
            ar_seen = 1'b1;
        end
        if(vif.S_AXI_RVALID && !ar_seen) begin
            `uvm_error("AXIL_PROTOCOL", "RVALID asserted without a prior AR handshake")
        end
        if(vif.S_AXI_RVALID && vif.S_AXI_RREADY) ar_seen = 1'b0;
    endtask
    task update_statistics();
        if(vif.S_AXI_AWVALID && vif.S_AXI_AWREADY) aw_handshakes++;
        if(vif.S_AXI_WVALID && vif.S_AXI_WREADY) w_handshakes++;
        if(vif.S_AXI_BVALID && vif.S_AXI_BREADY) b_handshakes++;
        if(vif.S_AXI_ARVALID && vif.S_AXI_ARREADY) ar_handshakes++;
        if(vif.S_AXI_RVALID && vif.S_AXI_RREADY) r_handshakes++;
        if(vif.S_AXI_AWVALID && !vif.S_AXI_AWREADY) aw_stall_cycles++;
        if(vif.S_AXI_WVALID && !vif.S_AXI_WREADY) w_stall_cycles++;
        if(vif.S_AXI_BVALID && !vif.S_AXI_BREADY) b_stall_cycles++;
        if(vif.S_AXI_ARVALID && !vif.S_AXI_ARREADY) ar_stall_cycles++;
        if(vif.S_AXI_RVALID && !vif.S_AXI_RREADY) r_stall_cycles++;
    endtask
    task update_hold_state();
        aw_hold_active = vif.S_AXI_AWVALID && !vif.S_AXI_AWREADY;
        if(aw_hold_active) awaddr_hold = vif.S_AXI_AWADDR;
        w_hold_active = vif.S_AXI_WVALID && !vif.S_AXI_WREADY;
        if(w_hold_active) begin
            wdata_hold = vif.S_AXI_WDATA;
            wstrb_hold = vif.S_AXI_WSTRB;
        end
        b_hold_active = vif.S_AXI_BVALID && !vif.S_AXI_BREADY;
        if(b_hold_active) bresp_hold = vif.S_AXI_BRESP;
        ar_hold_active = vif.S_AXI_ARVALID && !vif.S_AXI_ARREADY;
        if(ar_hold_active) araddr_hold = vif.S_AXI_ARADDR;
        r_hold_active = vif.S_AXI_RVALID && !vif.S_AXI_RREADY;
        if(r_hold_active) begin
            rdata_hold = vif.S_AXI_RDATA;
            rresp_hold = vif.S_AXI_RRESP;
        end
    endtask
    function void report_summary(string report_context = "protocol checker");
        `uvm_info("AXIL_PROTOCOL", $sformatf(
            "%s: handshakes AW=%0d W=%0d B=%0d AR=%0d R=%0d | stall cycles AW=%0d W=%0d B=%0d AR=%0d R=%0d",
            report_context, aw_handshakes, w_handshakes, b_handshakes, ar_handshakes, r_handshakes,
            aw_stall_cycles, w_stall_cycles, b_stall_cycles, ar_stall_cycles, r_stall_cycles), UVM_NONE)
    endfunction
endclass
