class AXIL_Coverage extends uvm_subscriber #(AXIL_Transaction);
    `uvm_component_utils(AXIL_Coverage)
    typedef enum bit [3:0] {
        AXIL_TIMING_SAME_G0 = 4'd0,
        AXIL_TIMING_AW_G1 = 4'd1,
        AXIL_TIMING_AW_G2 = 4'd2,
        AXIL_TIMING_AW_G3 = 4'd3,
        AXIL_TIMING_AW_G4P = 4'd4,
        AXIL_TIMING_W_G1 = 4'd5,
        AXIL_TIMING_W_G2 = 4'd6,
        AXIL_TIMING_W_G3 = 4'd7,
        AXIL_TIMING_W_G4P = 4'd8
    } AXIL_TIMING_CLASS_E;
    AXIL_OP_E sample_op;
    bit [31:0] sample_addr;
    bit [3:0] sample_strb;
    AXIL_WRITE_ORDER_E sample_write_order;
    bit [2:0] sample_gap_bucket;
    AXIL_TIMING_CLASS_E sample_timing_class;
    bit sample_timing_valid;
    bit [1:0] sample_aw_stall_bucket;
    bit [1:0] sample_w_stall_bucket;
    bit [1:0] sample_b_stall_bucket;
    bit [1:0] sample_ar_stall_bucket;
    bit [1:0] sample_r_stall_bucket;
    covergroup AXIL_CG;
        option.per_instance = 1;
        // Basic transaction coverage
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
        // Observed AXI write timing coverage
        cp_write_order: coverpoint sample_write_order iff(sample_op == AXIL_WRITE) {
            bins same = {AXIL_AW_W_SAME};
            bins aw_first = {AXIL_AW_FIRST};
            bins w_first = {AXIL_W_FIRST};
        }

        cp_handshake_gap: coverpoint sample_gap_bucket iff(sample_op == AXIL_WRITE) {
            bins gap_0 = {3'd0};
            bins gap_1 = {3'd1};
            bins gap_2 = {3'd2};
            bins gap_3 = {3'd3};
            bins gap_4_plus = {3'd4};
        }

        cp_timing_class: coverpoint sample_timing_class
        iff(sample_op == AXIL_WRITE && sample_timing_valid) {
            bins same_g0 = {AXIL_TIMING_SAME_G0};
            bins aw_g1 = {AXIL_TIMING_AW_G1};
            bins aw_g2 = {AXIL_TIMING_AW_G2};
            bins aw_g3 = {AXIL_TIMING_AW_G3};
            bins aw_g4p = {AXIL_TIMING_AW_G4P};
            bins w_g1 = {AXIL_TIMING_W_G1};
            bins w_g2 = {AXIL_TIMING_W_G2};
            bins w_g3 = {AXIL_TIMING_W_G3};
            bins w_g4p = {AXIL_TIMING_W_G4P};
        }
        cp_aw_stall: coverpoint sample_aw_stall_bucket iff(sample_op == AXIL_WRITE) {
            bins stall_0 = {2'd0};
            bins stall_1 = {2'd1};
            bins stall_2 = {2'd2};
            bins stall_3_plus = {2'd3};
        }
        cp_w_stall: coverpoint sample_w_stall_bucket iff(sample_op == AXIL_WRITE) {
            bins stall_0 = {2'd0};
            bins stall_1 = {2'd1};
            bins stall_2 = {2'd2};
            bins stall_3_plus = {2'd3};
        }
        cp_b_stall: coverpoint sample_b_stall_bucket iff(sample_op == AXIL_WRITE) {
            bins stall_0 = {2'd0};
            bins stall_1 = {2'd1};
            bins stall_2 = {2'd2};
            bins stall_3_plus = {2'd3};
        }
        cp_ar_stall: coverpoint sample_ar_stall_bucket iff(sample_op == AXIL_READ) {
            bins stall_0 = {2'd0};
            bins stall_1 = {2'd1};
            bins stall_2 = {2'd2};
            bins stall_3_plus = {2'd3};
        }
        cp_r_stall: coverpoint sample_r_stall_bucket iff(sample_op == AXIL_READ) {
            bins stall_0 = {2'd0};
            bins stall_1 = {2'd1};
            bins stall_2 = {2'd2};
            bins stall_3_plus = {2'd3};
        }
        // Cross coverage
        op_x_addr: cross cp_op, cp_addr;
        addr_x_strb: cross cp_addr, cp_strb;
        order_x_addr: cross cp_write_order, cp_addr;
        order_x_b_stall: cross cp_write_order, cp_b_stall;
        addr_x_r_stall: cross cp_addr, cp_r_stall;
    endgroup
    function new(string name = "AXIL_Coverage", uvm_component parent = null);
        super.new(name, parent);
        AXIL_CG = new();
    endfunction
    function automatic bit [1:0] stall_bucket(longint unsigned stall_cycles);
        if(stall_cycles >= 3) return 2'd3;
        return stall_cycles[1:0];
    endfunction
    function void write(AXIL_Transaction tr);
        sample_op = tr.op;
        sample_addr = tr.addr;
        sample_strb = tr.strb;
        sample_write_order = AXIL_AW_W_SAME;
        sample_gap_bucket = 3'd0;
        sample_timing_class = AXIL_TIMING_SAME_G0;
        sample_timing_valid = 1'b0;
        sample_aw_stall_bucket = 2'd0;
        sample_w_stall_bucket = 2'd0;
        sample_b_stall_bucket = 2'd0;
        sample_ar_stall_bucket = 2'd0;
        sample_r_stall_bucket = 2'd0;
        if(tr.op == AXIL_WRITE) begin
            sample_write_order = tr.write_order;
            sample_aw_stall_bucket = stall_bucket(tr.aw_stall_cycles);
            sample_w_stall_bucket = stall_bucket(tr.w_stall_cycles);
            sample_b_stall_bucket = stall_bucket(tr.b_stall_cycles);
            if(tr.handshake_gap >= 4) sample_gap_bucket = 3'd4;
            else sample_gap_bucket = tr.handshake_gap[2:0];
            case(tr.write_order)
                AXIL_AW_W_SAME: begin
                    if(tr.handshake_gap != 0) begin
                        `uvm_error("AXIL_COV", $sformatf(
                            "Invalid observed timing: SAME with gap=%0d", tr.handshake_gap))
                    end
                    else begin
                        sample_timing_class = AXIL_TIMING_SAME_G0;
                        sample_timing_valid = 1'b1;
                    end
                end
                AXIL_AW_FIRST: begin
                    if(tr.handshake_gap == 0) begin
                        `uvm_error("AXIL_COV", "Invalid observed timing: AW_FIRST with gap=0")
                    end
                    else begin
                        case(tr.handshake_gap)
                            1: sample_timing_class = AXIL_TIMING_AW_G1;
                            2: sample_timing_class = AXIL_TIMING_AW_G2;
                            3: sample_timing_class = AXIL_TIMING_AW_G3;
                            default: sample_timing_class = AXIL_TIMING_AW_G4P;
                        endcase
                        sample_timing_valid = 1'b1;
                    end
                end
                AXIL_W_FIRST: begin
                    if(tr.handshake_gap == 0) begin
                        `uvm_error("AXIL_COV", "Invalid observed timing: W_FIRST with gap=0")
                    end
                    else begin
                        case(tr.handshake_gap)
                            1: sample_timing_class = AXIL_TIMING_W_G1;
                            2: sample_timing_class = AXIL_TIMING_W_G2;
                            3: sample_timing_class = AXIL_TIMING_W_G3;
                            default: sample_timing_class = AXIL_TIMING_W_G4P;
                        endcase
                        sample_timing_valid = 1'b1;
                    end
                end
                default: begin
                    `uvm_error("AXIL_COV", $sformatf("Invalid observed write_order=%0d", tr.write_order))
                end
            endcase
        end
        else begin
            sample_ar_stall_bucket = stall_bucket(tr.ar_stall_cycles);
            sample_r_stall_bucket = stall_bucket(tr.r_stall_cycles);
        end
        AXIL_CG.sample();
        `uvm_info("AXIL_COV", $sformatf(
            "Sampled op=%0d addr=0x%08h strb=0x%01h order=%0d gap=%0d awstall=%0d wstall=%0d bstall=%0d arstall=%0d rstall=%0d",
            sample_op, sample_addr, sample_strb, sample_write_order,
            tr.handshake_gap, tr.aw_stall_cycles, tr.w_stall_cycles,
            tr.b_stall_cycles, tr.ar_stall_cycles, tr.r_stall_cycles), UVM_HIGH)
    endfunction
    function void report_phase(uvm_phase phase);
        real coverage;
        super.report_phase(phase);
        coverage = AXIL_CG.get_inst_coverage();
        `uvm_info("AXIL_COV", $sformatf("AXI-Lite functional coverage = %.2f%%", coverage), UVM_NONE)
    endfunction
endclass
