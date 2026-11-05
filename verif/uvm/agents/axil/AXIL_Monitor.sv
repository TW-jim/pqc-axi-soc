class AXIL_Monitor extends uvm_monitor;
    `uvm_component_utils(AXIL_Monitor)
    virtual AXIL_if vif;
    uvm_analysis_port #(AXIL_Transaction) ap;
    bit [31:0] awaddr;
    bit aw_pending;
    bit [31:0] wdata;
    bit [3:0] wstrb;
    bit w_pending;
    bit [31:0] araddr;
    bit ar_pending;
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
        forever begin
            @(posedge vif.ACLK);
            if(!vif.ARESETn) begin
                aw_pending = 1'b0;
                w_pending = 1'b0;
                ar_pending = 1'b0;
            end
            else begin
                // Write address handshake
                if(vif.S_AXI_AWVALID && vif.S_AXI_AWREADY) begin
                    awaddr = vif.S_AXI_AWADDR;
                    aw_pending = 1'b1;
                end
                // Write data handshake
                if(vif.S_AXI_WVALID && vif.S_AXI_WREADY) begin
                    wdata = vif.S_AXI_WDATA;
                    wstrb = vif.S_AXI_WSTRB;
                    w_pending = 1'b1;
                end
                // Write response
                if(vif.S_AXI_BVALID && vif.S_AXI_BREADY) begin
                    tr = AXIL_Transaction::type_id::create("mon_write_tr");
                    tr.op = AXIL_WRITE;
                    tr.addr = awaddr;
                    tr.data = wdata;
                    tr.strb = wstrb;
                    tr.resp = vif.S_AXI_BRESP;
                    ap.write(tr);
                    aw_pending = 1'b0;
                    w_pending = 1'b0;
                end
                // Read address
                if(vif.S_AXI_ARVALID && vif.S_AXI_ARREADY) begin
                    araddr = vif.S_AXI_ARADDR;
                    ar_pending = 1'b1;
                end
                // Read response
                if(vif.S_AXI_RVALID && vif.S_AXI_RREADY) begin
                    tr = AXIL_Transaction::type_id::create("mon_read_tr");
                    tr.op = AXIL_READ;
                    tr.addr = araddr;
                    tr.rdata = vif.S_AXI_RDATA;
                    tr.resp = vif.S_AXI_RRESP;
                    ap.write(tr);
                    ar_pending = 1'b0;
                end
            end
        end
    endtask
endclass
