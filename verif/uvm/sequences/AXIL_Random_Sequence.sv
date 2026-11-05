class AXIL_Random_Sequence extends uvm_sequence #(AXIL_Transaction);
    `uvm_object_utils(AXIL_Random_Sequence)
    localparam bit [31:0] ADDR_CONTROL = 32'h0000_0000;
    localparam bit [31:0] ADDR_STATUS = 32'h0000_0004;
    localparam bit [31:0] ADDR_SRC_ADDR = 32'h0000_0008;
    localparam bit [31:0] ADDR_DST_ADDR = 32'h0000_000C;
    int unsigned num_transactions = 100;
    function new(string name = "AXIL_Random_Sequence");
        super.new(name);
    endfunction
    task body();
        AXIL_Transaction tr;
        `uvm_info("RANDOM_SEQ", $sformatf(
                "Starting AXI-Lite random sequence with %0d transactions",
                num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            tr = AXIL_Transaction::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize() with {
                addr inside {
                    ADDR_CONTROL,
                    ADDR_STATUS,
                    ADDR_SRC_ADDR,
                    ADDR_DST_ADDR
                };
                if(op == AXIL_READ) {
                    data == 32'b0;
                    strb == 4'b0000;
                    write_order == AXIL_AW_W_SAME;
                    channel_delay == 0;
                }
                else {
                    strb != 4'b0000;
                    write_order inside {
                        AXIL_AW_W_SAME,
                        AXIL_AW_FIRST,
                        AXIL_W_FIRST
                    };
                    channel_delay inside {[0:3]};
                }
            }) begin
                `uvm_fatal("RANDOM_SEQ", "AXIL_Transaction randomization failed")
            end
            finish_item(tr);
        end
        `uvm_info("RANDOM_SEQ", $sformatf("Completed %0d random AXI-Lite transactions",
                num_transactions), UVM_MEDIUM)
    endtask
endclass
