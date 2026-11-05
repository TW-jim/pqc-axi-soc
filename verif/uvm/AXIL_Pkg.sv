package AXIL_Pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "transactions/AXIL_Transaction.sv"
    `include "agents/axil/AXIL_Sequencer.sv"
    `include "agents/axil/AXIL_Driver.sv"
    `include "agents/axil/AXIL_Monitor.sv"
    `include "agents/axil/AXIL_Agent.sv"
    `include "sequences/AXIL_Smoke_Sequence.sv"
    `include "sequences/AXIL_Random_Sequence.sv"
    `include "scoreboard/AXIL_Scoreboard.sv"
    `include "coverage/AXIL_Coverage.sv"
    `include "env/AXIL_Env.sv"
    `include "tests/AXIL_Base_Test.sv"
    `include "tests/AXIL_Random_Test.sv"
endpackage
