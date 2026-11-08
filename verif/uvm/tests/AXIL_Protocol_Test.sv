class AXIL_Protocol_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Protocol_Test)
    AXIL_Protocol_Checker protocol_checker;
    function new(string name = "AXIL_Protocol_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        AXIL_Protocol_Sequence seq;
        phase.raise_objection(this);
        protocol_checker = env.agent.get_protocol_checker();
        if(protocol_checker == null)
            `uvm_fatal("PROTOCOL_TEST", "AXIL protocol checker handle is null")
        seq = AXIL_Protocol_Sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        repeat(5)
            @(posedge env.agent.driver.vif.ACLK);
        check_protocol_counts();
        protocol_checker.report_summary("AXIL_Protocol_Test");
        phase.drop_objection(this);
    endtask
    function void check_protocol_counts();
        if(protocol_checker.aw_handshakes != 12)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 12 AW handshakes, observed %0d",
                protocol_checker.aw_handshakes))
        if(protocol_checker.w_handshakes != 12)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 12 W handshakes, observed %0d",
                protocol_checker.w_handshakes))
        if(protocol_checker.b_handshakes != 12)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 12 B handshakes, observed %0d",
                protocol_checker.b_handshakes))
        if(protocol_checker.ar_handshakes != 16)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 16 AR handshakes, observed %0d",
                protocol_checker.ar_handshakes))
        if(protocol_checker.r_handshakes != 16)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 16 R handshakes, observed %0d",
                protocol_checker.r_handshakes))
        if(protocol_checker.b_stall_cycles != 18)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 18 B stall cycles, observed %0d",
                protocol_checker.b_stall_cycles))
        if(protocol_checker.r_stall_cycles != 24)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 24 R stall cycles, observed %0d",
                protocol_checker.r_stall_cycles))
        if(protocol_checker.aw_stall_cycles != 0)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 0 AW stall cycles for this single-outstanding directed test, observed %0d",
                protocol_checker.aw_stall_cycles))
        if(protocol_checker.w_stall_cycles != 0)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 0 W stall cycles for this single-outstanding directed test, observed %0d",
                protocol_checker.w_stall_cycles))
        if(protocol_checker.ar_stall_cycles != 0)
            `uvm_error("PROTOCOL_TEST", $sformatf(
                "Expected 0 AR stall cycles for this single-outstanding directed test, observed %0d",
                protocol_checker.ar_stall_cycles))
    endfunction
endclass
