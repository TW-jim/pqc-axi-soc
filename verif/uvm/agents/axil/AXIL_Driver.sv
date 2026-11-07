class AXIL_Driver extends uvm_driver #(AXIL_Transaction);
    `uvm_component_utils(AXIL_Driver)
    virtual AXIL_if vif;
    function new(string name = "AXIL_Driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Driver cannot get virtual interface")
        end
    endfunction
    task run_phase(uvm_phase phase);
        AXIL_Transaction tr;
        drive_idle();
        wait(vif.ARESETn == 1'b1);
        forever begin
            seq_item_port.get_next_item(tr);
            `uvm_info("AXIL_DRIVER", tr.convert2string(), UVM_MEDIUM)
            if(tr.op == AXIL_WRITE) drive_write(tr);
            else drive_read(tr);
            seq_item_port.item_done();
        end
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
    // AW channel
    task drive_aw_now(AXIL_Transaction tr);
        int timeout_count;
        vif.S_AXI_AWADDR = tr.addr;
        vif.S_AXI_AWVALID = 1'b1;
        timeout_count = 0;
        while(!vif.S_AXI_AWREADY) begin
            @(posedge vif.ACLK);
            @(negedge vif.ACLK);
            timeout_count++;
            if(timeout_count > 100) `uvm_fatal("AXIL_DRIVER", "Timeout waiting for AWREADY")
        end
        @(posedge vif.ACLK);
        `uvm_info("AXIL_DRIVER", "AW handshake completed", UVM_HIGH)
        @(negedge vif.ACLK);
        vif.S_AXI_AWVALID = 1'b0;
    endtask
    task drive_aw(AXIL_Transaction tr);
        @(negedge vif.ACLK);
        drive_aw_now(tr);
    endtask
    // W channel
    task drive_w_now(AXIL_Transaction tr);
        int timeout_count;
        vif.S_AXI_WDATA = tr.data;
        vif.S_AXI_WSTRB = tr.strb;
        vif.S_AXI_WVALID = 1'b1;
        timeout_count = 0;
        while(!vif.S_AXI_WREADY) begin
            @(posedge vif.ACLK);
            @(negedge vif.ACLK);
            timeout_count++;
            if(timeout_count > 100) `uvm_fatal("AXIL_DRIVER", "Timeout waiting for WREADY")
        end
        @(posedge vif.ACLK);
        `uvm_info("AXIL_DRIVER", "W handshake completed", UVM_HIGH)
        @(negedge vif.ACLK);
        vif.S_AXI_WVALID = 1'b0;
    endtask
    task drive_w(AXIL_Transaction tr);
        @(negedge vif.ACLK);
        drive_w_now(tr);
    endtask
    // Write transaction
    task drive_write(AXIL_Transaction tr);
        int timeout_count;
        vif.S_AXI_BREADY = 1'b0;
        case(tr.write_order)
            AXIL_AW_W_SAME: begin
                @(negedge vif.ACLK);
                fork
                    drive_aw_now(tr);
                    drive_w_now(tr);
                join
            end
            AXIL_AW_FIRST: begin
                drive_aw(tr);
                repeat(tr.channel_delay) begin
                    @(negedge vif.ACLK);
                end
                drive_w_now(tr);
            end
            AXIL_W_FIRST: begin
                drive_w(tr);
                repeat(tr.channel_delay) begin
                    @(negedge vif.ACLK);
                end
                drive_aw_now(tr);
            end
            default: begin
                `uvm_fatal("AXIL_DRIVER", $sformatf("Invalid write_order=%0d", tr.write_order))
            end
        endcase
        // B response
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b1;
        timeout_count = 0;
        // Same principle:
        // sample BVALID before the rising-edge handshake.
        while(!vif.S_AXI_BVALID) begin
            @(posedge vif.ACLK);
            @(negedge vif.ACLK);
            timeout_count++;
            if(timeout_count > 100) begin
                `uvm_fatal("AXIL_DRIVER", $sformatf(
                        "Timeout waiting for BVALID: order=%0d delay=%0d",
                        tr.write_order, tr.channel_delay))
            end
        end
        tr.resp = vif.S_AXI_BRESP;
        @(posedge vif.ACLK);
        `uvm_info("AXIL_DRIVER", "B handshake completed", UVM_HIGH)
        @(negedge vif.ACLK);
        vif.S_AXI_BREADY = 1'b0;
    endtask
    // Read transaction
    task drive_read(AXIL_Transaction tr);
        int timeout_count;
        // AR channel
        @(negedge vif.ACLK);
        vif.S_AXI_ARADDR = tr.addr;
        vif.S_AXI_ARVALID = 1'b1;
        timeout_count = 0;
        while(!vif.S_AXI_ARREADY) begin
            @(posedge vif.ACLK);
            @(negedge vif.ACLK);
            timeout_count++;
            if(timeout_count > 100) `uvm_fatal("AXIL_DRIVER", "Timeout waiting for ARREADY")
        end
        @(posedge vif.ACLK);
        `uvm_info("AXIL_DRIVER", "AR handshake completed", UVM_HIGH)
        @(negedge vif.ACLK);
        vif.S_AXI_ARVALID = 1'b0;
        // R channel
        vif.S_AXI_RREADY = 1'b1;
        timeout_count = 0;
        while(!vif.S_AXI_RVALID) begin
            @(posedge vif.ACLK);
            @(negedge vif.ACLK);
            timeout_count++;
            if(timeout_count > 100) `uvm_fatal("AXIL_DRIVER", "Timeout waiting for RVALID")
        end
        tr.rdata = vif.S_AXI_RDATA;
        tr.resp = vif.S_AXI_RRESP;
        @(posedge vif.ACLK);
        `uvm_info("AXIL_DRIVER", "R handshake completed", UVM_HIGH)
        @(negedge vif.ACLK);
        vif.S_AXI_RREADY = 1'b0;
    endtask
endclass
