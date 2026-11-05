class AXIL_Env extends uvm_env;
    `uvm_component_utils(AXIL_Env)
    AXIL_Agent agent;
    AXIL_Scoreboard scoreboard;
    AXIL_Coverage coverage;
    function new(
        string name = "AXIL_Env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = AXIL_Agent::type_id::create("agent", this);
        scoreboard = AXIL_Scoreboard::type_id::create("scoreboard", this);
        coverage = AXIL_Coverage::type_id::create("coverage", this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.analysis_export);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass
