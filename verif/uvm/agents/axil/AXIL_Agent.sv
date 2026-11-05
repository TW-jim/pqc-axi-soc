class AXIL_Agent extends uvm_agent;
    `uvm_component_utils(AXIL_Agent)
    AXIL_Sequencer sequencer;
    AXIL_Driver driver;
    AXIL_Monitor monitor;
    function new(string name = "AXIL_Agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = AXIL_Sequencer::type_id::create("sequencer", this);
        driver = AXIL_Driver::type_id::create("driver", this);
        monitor = AXIL_Monitor::type_id::create("monitor", this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
