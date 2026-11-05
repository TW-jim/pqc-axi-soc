class AXIL_Base_Test extends uvm_test;
    `uvm_component_utils(AXIL_Base_Test)
    AXIL_Env env;
    function new(string name = "AXIL_Base_Test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = AXIL_Env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
        AXIL_Smoke_Sequence seq;
        phase.raise_objection(this);
        seq = AXIL_Smoke_Sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        repeat(5)
            @(posedge env.agent.driver.vif.ACLK);
        phase.drop_objection(this);
    endtask
endclass
