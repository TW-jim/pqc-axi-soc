typedef enum bit {
    AXIL_READ = 1'b0,
    AXIL_WRITE = 1'b1
} AXIL_OP_E;
typedef enum bit [1:0] {
    AXIL_AW_W_SAME = 2'd0,
    AXIL_AW_FIRST = 2'd1,
    AXIL_W_FIRST = 2'd2
} AXIL_WRITE_ORDER_E;
class AXIL_Transaction extends uvm_sequence_item;
    rand AXIL_OP_E op;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0] strb;
    rand AXIL_WRITE_ORDER_E write_order;
    rand bit [2:0] channel_delay;
    longint unsigned handshake_gap;
    bit [31:0] rdata;
    bit [1:0] resp;
    `uvm_object_utils(AXIL_Transaction)
    function new(string name = "AXIL_Transaction");
        super.new(name);
    endfunction
    function string convert2string();
        if(op == AXIL_WRITE) begin
            return $sformatf(
                    "WRITE addr=0x%08h data=0x%08h strb=0x%01h order=%0d delay=%0d gap=%0d resp=%0d",
                    addr, data, strb, write_order, channel_delay, handshake_gap, resp);
        end
        else begin
            return $sformatf("READ addr=0x%08h rdata=0x%08h resp=%0d", addr, rdata, resp);
        end
    endfunction
endclass
