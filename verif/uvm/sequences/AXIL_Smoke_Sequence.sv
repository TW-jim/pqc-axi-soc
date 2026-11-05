class AXIL_Smoke_Sequence extends uvm_sequence #(AXIL_Transaction);
    `uvm_object_utils(AXIL_Smoke_Sequence)
    localparam bit [31:0] ADDR_CONTROL = 32'h0000_0000;
    localparam bit [31:0] ADDR_STATUS = 32'h0000_0004;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    function new(string name = "AXIL_Smoke_Sequence");
        super.new(name);
    endfunction
    task body();
        `uvm_info("SMOKE_SEQ", "Starting AXI-Lite smoke sequence", UVM_MEDIUM)
        // Set MODE = 1
        write_reg(ADDR_CONTROL, 32'h0000_0002, 4'b1111);
        // Program source address
        write_reg(ADDR_SRC_ADDR, 32'h1234_5678, 4'b1111);
        // Program destination address
        write_reg(ADDR_DST_ADDR, 32'hA5A5_5A5A,
            4'b1111
        );
        // Read everything back
        read_reg(ADDR_CONTROL);
        read_reg(ADDR_SRC_ADDR);
        read_reg(ADDR_DST_ADDR);
        `uvm_info("SMOKE_SEQ", "AXI-Lite smoke sequence completed", UVM_MEDIUM)
    endtask
    task write_reg(
        bit [31:0] addr,
        bit [31:0] data,
        bit [3:0] strb
    );
        AXIL_Transaction tr;
        tr = AXIL_Transaction::type_id::create("write_tr");
        start_item(tr);
        tr.op = AXIL_WRITE;
        tr.addr = addr;
        tr.data = data;
        tr.strb = strb;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        finish_item(tr);
    endtask
    task read_reg(
        bit [31:0] addr
    );
        AXIL_Transaction tr;
        tr = AXIL_Transaction::type_id::create("read_tr");
        start_item(tr);
        tr.op = AXIL_READ;
        tr.addr = addr;
        tr.data = '0;
        tr.strb = '0;
        tr.write_order = AXIL_AW_W_SAME;
        tr.channel_delay = 0;
        finish_item(tr);
    endtask
endclass
