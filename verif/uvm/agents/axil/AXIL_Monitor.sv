class AXIL_Monitor extends uvm_monitor;
    `uvm_component_utils(AXIL_Monitor)
    virtual AXIL_if vif;
    uvm_analysis_port #(AXIL_Transaction) ap;
    bit [31:0] awaddr;
    bit aw_pending;
    longint unsigned aw_cycle;
    longint unsigned aw_stall_wait;
    longint unsigned aw_stall_observed;
    bit [31:0] wdata;
    bit [3:0] wstrb;
    bit w_pending;
    longint unsigned w_cycle;
    longint unsigned w_stall_wait;
    longint unsigned w_stall_observed;
    bit write_pair_ready;
    AXIL_WRITE_ORDER_E write_order_observed;
    longint unsigned handshake_gap_observed;
    bit [31:0] araddr;
    bit ar_pending;
    longint unsigned ar_stall_wait;
    longint unsigned ar_stall_observed;
    longint unsigned b_stall_cycles;
    longint unsigned r_stall_cycles;
    longint unsigned cycle_count;
    function new(string name = "AXIL_Monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Monitor cannot get virtual interface")
        end
    endfunction
    task clear_completed_write();
        aw_pending = 1'b0;
        w_pending = 1'b0;
        aw_cycle = 0;
        w_cycle = 0;
        aw_stall_observed = 0;
        w_stall_observed = 0;
        b_stall_cycles = 0;
        write_pair_ready = 1'b0;
        write_order_observed = AXIL_AW_W_SAME;
        handshake_gap_observed = 0;
    endtask
    task reset_state();
        aw_stall_wait = 0;
        w_stall_wait = 0;
        ar_pending = 1'b0;
        ar_stall_wait = 0;
        ar_stall_observed = 0;
        r_stall_cycles = 0;
        cycle_count = 0;
        clear_completed_write();
    endtask
    task run_phase(uvm_phase phase);
        AXIL_Transaction tr;
        reset_state();
        forever begin
            @(posedge vif.ACLK);
            if(!vif.ARESETn) reset_state();
            else begin
                cycle_count++;
                // Write address handshake
                if(vif.S_AXI_AWVALID && !vif.S_AXI_AWREADY) aw_stall_wait++;
                if(vif.S_AXI_AWVALID && vif.S_AXI_AWREADY) begin
                    if(aw_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "Received a new AW handshake while previous AW is still pending")
                    end
                    else begin
                        awaddr = vif.S_AXI_AWADDR;
                        aw_cycle = cycle_count;
                        aw_stall_observed = aw_stall_wait;
                        aw_stall_wait = 0;
                        aw_pending = 1'b1;
                    end
                end
                else if(!vif.S_AXI_AWVALID) aw_stall_wait = 0;
                // Write data handshake
                if(vif.S_AXI_WVALID && !vif.S_AXI_WREADY) w_stall_wait++;
                if(vif.S_AXI_WVALID && vif.S_AXI_WREADY) begin
                    if(w_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "Received a new W handshake while previous W is still pending")
                    end
                    else begin
                        wdata = vif.S_AXI_WDATA;
                        wstrb = vif.S_AXI_WSTRB;
                        w_cycle = cycle_count;
                        w_stall_observed = w_stall_wait;
                        w_stall_wait = 0;
                        w_pending = 1'b1;
                    end
                end
                else if(!vif.S_AXI_WVALID) w_stall_wait = 0;
                if(!write_pair_ready && aw_pending && w_pending) begin
                    if(aw_cycle == w_cycle) begin
                        write_order_observed = AXIL_AW_W_SAME;
                        handshake_gap_observed = 0;
                    end
                    else if(aw_cycle < w_cycle) begin
                        write_order_observed = AXIL_AW_FIRST;
                        handshake_gap_observed = w_cycle - aw_cycle;
                    end
                    else begin
                        write_order_observed = AXIL_W_FIRST;
                        handshake_gap_observed = aw_cycle - w_cycle;
                    end
                    write_pair_ready = 1'b1;
                end
                if(vif.S_AXI_BVALID && !vif.S_AXI_BREADY) b_stall_cycles++;
                // Write response
                if(vif.S_AXI_BVALID && vif.S_AXI_BREADY) begin
                    if(!write_pair_ready) begin
                        `uvm_error("AXIL_MONITOR", $sformatf(
                            "B response without complete AW/W transaction: aw_pending=%0d w_pending=%0d",
                            aw_pending, w_pending))
                    end
                    else begin
                        tr = AXIL_Transaction::type_id::create("mon_write_tr");
                        tr.op = AXIL_WRITE;
                        tr.addr = awaddr;
                        tr.data = wdata;
                        tr.strb = wstrb;
                        tr.resp = vif.S_AXI_BRESP;
                        tr.aw_stall_cycles = aw_stall_observed;
                        tr.w_stall_cycles = w_stall_observed;
                        tr.b_stall_cycles = b_stall_cycles;
                        tr.write_order = write_order_observed;
                        tr.handshake_gap = handshake_gap_observed;
                        `uvm_info("AXIL_MONITOR", $sformatf(
                            "Observed WRITE order=%0d gap=%0d awstall=%0d wstall=%0d bstall=%0d",
                            tr.write_order, tr.handshake_gap,
                            tr.aw_stall_cycles, tr.w_stall_cycles,
                            tr.b_stall_cycles), UVM_HIGH)
                        ap.write(tr);
                    end
                    clear_completed_write();
                end
                if(vif.S_AXI_ARVALID && !vif.S_AXI_ARREADY) ar_stall_wait++;
                if(vif.S_AXI_ARVALID && vif.S_AXI_ARREADY) begin
                    if(ar_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "Received a new AR handshake while previous AR is still pending")
                    end
                    else begin
                        araddr = vif.S_AXI_ARADDR;
                        ar_stall_observed = ar_stall_wait;
                        ar_stall_wait = 0;
                        ar_pending = 1'b1;
                    end
                end
                else if(!vif.S_AXI_ARVALID) ar_stall_wait = 0;
                if(vif.S_AXI_RVALID && !vif.S_AXI_RREADY) r_stall_cycles++;
                if(vif.S_AXI_RVALID && vif.S_AXI_RREADY) begin
                    if(!ar_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "R response received without a pending AR handshake")
                    end
                    else begin
                        tr = AXIL_Transaction::type_id::create("mon_read_tr");
                        tr.op = AXIL_READ;
                        tr.addr = araddr;
                        tr.rdata = vif.S_AXI_RDATA;
                        tr.resp = vif.S_AXI_RRESP;
                        tr.ar_stall_cycles = ar_stall_observed;
                        tr.r_stall_cycles = r_stall_cycles;
                        `uvm_info("AXIL_MONITOR", $sformatf(
                            "Observed READ arstall=%0d rstall=%0d",
                            tr.ar_stall_cycles, tr.r_stall_cycles), UVM_HIGH)
                        ap.write(tr);
                    end
                    ar_pending = 1'b0;
                    ar_stall_observed = 0;
                    r_stall_cycles = 0;
                end
            end
        end
    endtask
endclass
