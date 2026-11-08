class AXIL_Scoreboard extends uvm_scoreboard;
    `uvm_component_utils(AXIL_Scoreboard)
    uvm_analysis_imp #(
        AXIL_Transaction,
        AXIL_Scoreboard
    ) analysis_export;
    virtual AXIL_if vif;
    bit exp_mode;
    bit [31:0] exp_src_addr;
    bit [31:0] exp_dst_addr;
    localparam bit [31:0] ADDR_CONTROL = 32'h0000_0000;
    localparam bit [31:0] ADDR_STATUS = 32'h0000_0004;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual AXIL_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "AXIL_Scoreboard cannot get virtual interface")
        end
        reset_model();
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            @(negedge vif.ARESETn);
            reset_model();
            `uvm_info("AXIL_SB", "Reference model reset by ARESETn", UVM_HIGH)
        end
    endtask
    function void reset_model();
        exp_mode = 1'b0;
        exp_src_addr = 32'b0;
        exp_dst_addr = 32'b0;
    endfunction
    function automatic bit [31:0] apply_wstrb(
        bit [31:0] old_data,
        bit [31:0] new_data,
        bit [3:0] strb
    );
        bit [31:0] result;
        result = old_data;
        if(strb[0]) result[7:0] = new_data[7:0];
        if(strb[1]) result[15:8] = new_data[15:8];
        if(strb[2]) result[23:16] = new_data[23:16];
        if(strb[3]) result[31:24] = new_data[31:24];
        return result;
    endfunction
    function void write(AXIL_Transaction tr);
        bit [31:0] expected;
        // WRITE
        if(tr.op == AXIL_WRITE) begin
            if(tr.resp != 2'b00) begin
                `uvm_error("AXIL_SB", $sformatf("Write response error: resp=%0d addr=0x%08h",
                    tr.resp, tr.addr))
            end
            case(tr.addr)
                ADDR_CONTROL: if(tr.strb[0]) exp_mode = tr.data[1];
                // Read-only register
                ADDR_STATUS: ;
                ADDR_SRC_ADDR: exp_src_addr = apply_wstrb(exp_src_addr, tr.data, tr.strb);
                ADDR_DST_ADDR: exp_dst_addr = apply_wstrb(exp_dst_addr, tr.data, tr.strb);
                default: ;
            endcase
            `uvm_info("AXIL_SB", $sformatf(
                "Observed WRITE addr=0x%08h data=0x%08h strb=0x%01h order=%0d gap=%0d bstall=%0d resp=%0d",
                tr.addr, tr.data, tr.strb, tr.write_order,
                tr.handshake_gap, tr.b_stall_cycles, tr.resp), UVM_MEDIUM)
        end
        // READ
        else begin
            case(tr.addr)
                ADDR_CONTROL: expected = {30'b0, exp_mode, 1'b0};
                // Busy/Done/Error are all held at zero
                // in the first smoke test.
                ADDR_STATUS: expected = 32'b0;
                ADDR_SRC_ADDR: expected = exp_src_addr;
                ADDR_DST_ADDR: expected = exp_dst_addr;
                default: expected = 32'b0;
            endcase
            if(tr.resp != 2'b00) begin
                `uvm_error("AXIL_SB", $sformatf(
                    "Read response error: resp=%0d addr=0x%08h", tr.resp, tr.addr))
            end
            if(tr.rdata != expected) begin
                `uvm_error("AXIL_SB", $sformatf(
                    "READ MISMATCH addr=0x%08h expected=0x%08h actual=0x%08h rstall=%0d",
                    tr.addr, expected, tr.rdata, tr.r_stall_cycles))
            end
            else begin
                `uvm_info("AXIL_SB", $sformatf(
                    "READ PASS addr=0x%08h data=0x%08h rstall=%0d",
                    tr.addr, tr.rdata, tr.r_stall_cycles), UVM_LOW)
            end
        end
    endfunction
endclass
