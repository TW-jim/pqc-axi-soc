class AXIL_Protocol_Sequence extends uvm_sequence #(AXIL_Transaction);
    `uvm_object_utils(AXIL_Protocol_Sequence)
    localparam bit [31:0] ADDR_CONTROL = 32'h0000_0000;
    localparam bit [31:0] ADDR_STATUS = 32'h0000_0004;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Protocol_Sequence");
        super.new(name);
    endfunction
    task body();
        `uvm_info("PROTOCOL_SEQ",
            "Starting AXI-Lite five-channel protocol stress sequence", UVM_MEDIUM)
        write_reg(ADDR_DST_ADDR, 32'h1000_0000, AXIL_AW_W_SAME, 0, 0);
        write_reg(ADDR_DST_ADDR, 32'h1000_0001, AXIL_AW_W_SAME, 0, 1);
        write_reg(ADDR_DST_ADDR, 32'h1000_0002, AXIL_AW_W_SAME, 0, 2);
        write_reg(ADDR_DST_ADDR, 32'h1000_0003, AXIL_AW_W_SAME, 0, 3);
        write_reg(ADDR_DST_ADDR, 32'h2000_0000, AXIL_AW_FIRST, 0, 0);
        write_reg(ADDR_DST_ADDR, 32'h2000_0001, AXIL_AW_FIRST, 1, 1);
        write_reg(ADDR_DST_ADDR, 32'h2000_0002, AXIL_AW_FIRST, 2, 2);
        write_reg(ADDR_DST_ADDR, 32'h2000_0003, AXIL_AW_FIRST, 3, 3);
        write_reg(ADDR_DST_ADDR, 32'h3000_0000, AXIL_W_FIRST, 0, 0);
        write_reg(ADDR_DST_ADDR, 32'h3000_0001, AXIL_W_FIRST, 1, 1);
        write_reg(ADDR_DST_ADDR, 32'h3000_0002, AXIL_W_FIRST, 2, 2);
        write_reg(ADDR_DST_ADDR, 32'h3000_0003, AXIL_W_FIRST, 3, 3);
        read_reg(ADDR_CONTROL, 0);
        read_reg(ADDR_CONTROL, 1);
        read_reg(ADDR_CONTROL, 2);
        read_reg(ADDR_CONTROL, 3);
        read_reg(ADDR_STATUS, 0);
        read_reg(ADDR_STATUS, 1);
        read_reg(ADDR_STATUS, 2);
        read_reg(ADDR_STATUS, 3);
        read_reg(ADDR_SRC_ADDR, 0);
        read_reg(ADDR_SRC_ADDR, 1);
        read_reg(ADDR_SRC_ADDR, 2);
        read_reg(ADDR_SRC_ADDR, 3);
        read_reg(ADDR_DST_ADDR, 0);
        read_reg(ADDR_DST_ADDR, 1);
        read_reg(ADDR_DST_ADDR, 2);
        read_reg(ADDR_DST_ADDR, 3);
        `uvm_info("PROTOCOL_SEQ",
            "AXI-Lite five-channel protocol stress sequence completed", UVM_MEDIUM)
    endtask
    task write_reg(
        bit [31:0] addr,
        bit [31:0] data,
        AXIL_WRITE_ORDER_E write_order,
        bit [2:0] channel_delay,
        bit [2:0] bready_delay
    );
        AXIL_Transaction tr;
        tr = AXIL_Transaction::type_id::create("protocol_write_tr");
        start_item(tr);
        tr.op = AXIL_WRITE;
        tr.addr = addr;
        tr.data = data;
        tr.strb = 4'hF;
        tr.write_order = write_order;
        tr.channel_delay = channel_delay;
        tr.bready_delay = bready_delay;
        tr.rready_delay = 0;
        finish_item(tr);
    endtask
    task read_reg(
        bit [31:0] addr,
        bit [2:0] rready_delay
    );
        AXIL_Transaction tr;
        tr = AXIL_Transaction::type_id::create("protocol_read_tr");
        start_item(tr);
        tr.op = AXIL_READ;
        tr.addr = addr;
        tr.data = 32'b0;
        tr.strb = 4'b0000;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        tr.bready_delay = 0;
        tr.rready_delay = rready_delay;
        finish_item(tr);
    endtask
endclass
