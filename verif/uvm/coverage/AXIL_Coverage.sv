class AXIL_Coverage extends uvm_subscriber #(AXIL_Transaction);
    `uvm_component_utils(AXIL_Coverage)
    AXIL_OP_E sample_op;
    bit [31:0] sample_addr;
    bit [3:0] sample_strb;
    covergroup AXIL_CG;
        option.per_instance = 1;
        cp_op: coverpoint sample_op {
            bins read = {AXIL_READ};
            bins write = {AXIL_WRITE};
        }
        cp_addr: coverpoint sample_addr {
            bins control = {32'h0000_0000};
            bins status = {32'h0000_0004};
            bins src_addr = {32'h0000_0008};
            bins dst_addr = {32'h0000_000C};
        }
        cp_strb: coverpoint sample_strb iff(sample_op == AXIL_WRITE) {
            bins strb_values[] = {[4'h1:4'hF]};
        }
        op_x_addr: cross cp_op, cp_addr;
        addr_x_strb: cross cp_addr, cp_strb;
    endgroup
    function new(string name = "AXIL_Coverage", uvm_component parent = null);
        super.new(name, parent);
        AXIL_CG = new();
    endfunction
    function void write(AXIL_Transaction tr);
        sample_op = tr.op;
        sample_addr = tr.addr;
        sample_strb = tr.strb;
        AXIL_CG.sample();
        `uvm_info("AXIL_COV", $sformatf("Sampled op=%0d addr=0x%08h strb=0x%01h",
                sample_op, sample_addr, sample_strb), UVM_HIGH)
    endfunction
    function void report_phase(uvm_phase phase);
        real coverage;
        super.report_phase(phase);
        coverage = AXIL_CG.get_inst_coverage();
        `uvm_info("AXIL_COV", $sformatf("AXI-Lite functional coverage = %.2f%%", coverage), UVM_NONE)
    endfunction
endclass