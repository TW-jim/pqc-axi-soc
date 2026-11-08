class AXIL_Coverage_Closure_Sequence extends uvm_sequence #(AXIL_Transaction);
    `uvm_object_utils(AXIL_Coverage_Closure_Sequence)
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Coverage_Closure_Sequence");
        super.new(name);
    endfunction
    task body();
        AXIL_Transaction tr;
        `uvm_info("CLOSURE_SEQ", "Starting AXI-Lite functional coverage closure sequence", UVM_MEDIUM)
        // Previously identified v2 hole: SRC_ADDR x WSTRB=4'hA.
        // With reset value 0 and data A5C35A96, WSTRB=1010 updates
        // byte[3] and byte[1], producing A5005A00.
        tr = AXIL_Transaction::type_id::create("write_src_strba");
        start_item(tr);
        tr.op = AXIL_WRITE;
        tr.addr = ADDR_SRC_ADDR;
        tr.data = 32'hA5C3_5A96;
        tr.strb = 4'hA;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        tr.bready_delay = 0;
        tr.rready_delay = 0;
        finish_item(tr);
        tr = AXIL_Transaction::type_id::create("read_src");
        start_item(tr);
        tr.op = AXIL_READ;
        tr.addr = ADDR_SRC_ADDR;
        tr.data = 32'b0;
        tr.strb = 4'b0000;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        tr.bready_delay = 0;
        tr.rready_delay = 0;
        finish_item(tr);
        // v3_full hole: DST_ADDR x WSTRB=4'hD.
        // Coverage-bin mapping note: values [4'h1:4'hF] are expanded in
        // ascending order, so dst_addr_x_strb_values[12] maps to WSTRB=4'hD.
        // With reset value 0 and data C3A55A96, WSTRB=1101 updates
        // byte[3], byte[2], and byte[0], producing C3A50096.
        tr = AXIL_Transaction::type_id::create("write_dst_strbd");
        start_item(tr);
        tr.op = AXIL_WRITE;
        tr.addr = ADDR_DST_ADDR;
        tr.data = 32'hC3A5_5A96;
        tr.strb = 4'hD;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        tr.bready_delay = 0;
        tr.rready_delay = 0;
        finish_item(tr);
        tr = AXIL_Transaction::type_id::create("read_dst");
        start_item(tr);
        tr.op = AXIL_READ;
        tr.addr = ADDR_DST_ADDR;
        tr.data = 32'b0;
        tr.strb = 4'b0000;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        tr.bready_delay = 0;
        tr.rready_delay = 0;
        finish_item(tr);
        `uvm_info("CLOSURE_SEQ", "AXI-Lite functional coverage closure sequence completed", UVM_MEDIUM)
    endtask
endclass
