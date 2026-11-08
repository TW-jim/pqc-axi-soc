class AXIL_Sequencer extends uvm_sequencer #(AXIL_Transaction);
    `uvm_component_utils(AXIL_Sequencer)
    function new(string name = "AXIL_Sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
