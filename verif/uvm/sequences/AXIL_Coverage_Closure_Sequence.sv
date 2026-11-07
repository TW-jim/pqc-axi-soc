class AXIL_Coverage_Closure_Sequence extends uvm_sequence #(AXIL_Transaction);
    `uvm_object_utils(AXIL_Coverage_Closure_Sequence)
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    function new(string name = "AXIL_Coverage_Closure_Sequence");
        super.new(name);
    endfunction
    task body();
        AXIL_Transaction tr;
        `uvm_info("CLOSURE_SEQ", "Starting AXI-Lite functional coverage closure sequence", UVM_MEDIUM)
        tr = AXIL_Transaction::type_id::create("write_src_strba");
        start_item(tr);
        tr.op = AXIL_WRITE;
        tr.addr = ADDR_SRC_ADDR;
        tr.data = 32'hA5C3_5A96;
        tr.strb = 4'hA;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        finish_item(tr);
        tr = AXIL_Transaction::type_id::create("read_src");
        start_item(tr);
        tr.op = AXIL_READ;
        tr.addr = ADDR_SRC_ADDR;
        tr.data = 32'b0;
        tr.strb = 4'b0000;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        finish_item(tr);
        `uvm_info("CLOSURE_SEQ", "AXI-Lite functional coverage closure sequence completed", UVM_MEDIUM)
    endtask
endclass