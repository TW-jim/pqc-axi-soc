class AXIL_Random_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Random_Test)
    function new(string name = "AXIL_Random_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        AXIL_Random_Sequence seq;
        phase.raise_objection(this);
        seq = AXIL_Random_Sequence::type_id::create("seq");
        seq.num_transactions = 100;
        seq.start(env.agent.sequencer);
        repeat(5)
            @(posedge env.agent.driver.vif.ACLK);
        phase.drop_objection(this);
    endtask
endclass
