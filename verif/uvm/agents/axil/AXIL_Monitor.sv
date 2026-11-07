class AXIL_Monitor extends uvm_monitor;
    `uvm_component_utils(AXIL_Monitor)
    virtual AXIL_if vif;
    uvm_analysis_port #(AXIL_Transaction) ap;
    bit [31:0] awaddr;
    bit aw_pending;
    longint unsigned aw_cycle;
    bit [31:0] wdata;
    bit [3:0] wstrb;
    bit w_pending;
    longint unsigned w_cycle;
    bit [31:0] araddr;
    bit ar_pending;
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
    task run_phase(uvm_phase phase);
        AXIL_Transaction tr;
        aw_pending = 1'b0;
        w_pending = 1'b0;
        ar_pending = 1'b0;
        aw_cycle = 0;
        w_cycle = 0;
        cycle_count = 0;
        forever begin
            @(posedge vif.ACLK);
            if(!vif.ARESETn) begin
                aw_pending = 1'b0;
                w_pending = 1'b0;
                ar_pending = 1'b0;
                aw_cycle = 0;
                w_cycle = 0;
                cycle_count = 0;
            end
            else begin
                cycle_count++;
                // Write address handshake
                if(vif.S_AXI_AWVALID && vif.S_AXI_AWREADY) begin
                    if(aw_pending) begin
                        `uvm_error(
                            "AXIL_MONITOR",
                            "Received a new AW handshake while previous AW is still pending"
                        )
                    end
                    awaddr = vif.S_AXI_AWADDR;
                    aw_cycle = cycle_count;
                    aw_pending = 1'b1;
                end
                // Write data handshake
                if(vif.S_AXI_WVALID && vif.S_AXI_WREADY) begin
                    if(w_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "Received a new W handshake while previous W is still pending")
                    end
                    wdata = vif.S_AXI_WDATA;
                    wstrb = vif.S_AXI_WSTRB;
                    w_cycle = cycle_count;
                    w_pending = 1'b1;
                end
                // Write response
                if(vif.S_AXI_BVALID && vif.S_AXI_BREADY) begin
                    if(!(aw_pending && w_pending)) begin
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
                        if(aw_cycle == w_cycle) begin
                            tr.write_order = AXIL_AW_W_SAME;
                            tr.handshake_gap = 0;
                        end
                        else if(aw_cycle < w_cycle) begin
                            tr.write_order = AXIL_AW_FIRST;
                            tr.handshake_gap = w_cycle - aw_cycle;
                        end
                        else begin
                            tr.write_order = AXIL_W_FIRST;
                            tr.handshake_gap = aw_cycle - w_cycle;
                        end
                        `uvm_info("AXIL_MONITOR", $sformatf("Observed WRITE order=%0d gap=%0d",
                                tr.write_order, tr.handshake_gap), UVM_HIGH)
                        ap.write(tr);
                    end
                    aw_pending = 1'b0;
                    w_pending = 1'b0;
                end
                // Read address handshake
                if(vif.S_AXI_ARVALID && vif.S_AXI_ARREADY) begin
                    if(ar_pending) begin
                        `uvm_error("AXIL_MONITOR",
                            "Received a new AR handshake while previous AR is still pending")
                    end
                    araddr = vif.S_AXI_ARADDR;
                    ar_pending = 1'b1;
                end
                // Read response
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
                        ap.write(tr);
                    end
                    ar_pending = 1'b0;
                end
            end
        end
    endtask
endclass
