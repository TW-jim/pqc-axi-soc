class AXIL_Coverage_Closure_Test extends AXIL_Base_Test;
    `uvm_component_utils(AXIL_Coverage_Closure_Test)
    function new(string name = "AXIL_Coverage_Closure_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        AXIL_Coverage_Closure_Sequence seq;
        phase.raise_objection(this);
        seq = AXIL_Coverage_Closure_Sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass
