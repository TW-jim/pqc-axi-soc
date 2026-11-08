class AXIL_Agent extends uvm_agent;
    `uvm_component_utils(AXIL_Agent)
    AXIL_Sequencer sequencer;
    AXIL_Driver driver;
    AXIL_Monitor monitor;
    AXIL_Protocol_Checker protocol_checker;
    function new(string name = "AXIL_Agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = AXIL_Monitor::type_id::create("monitor", this);
        protocol_checker = AXIL_Protocol_Checker::type_id::create("protocol_checker", this);
        if(get_is_active() == UVM_ACTIVE) begin
            sequencer = AXIL_Sequencer::type_id::create("sequencer", this);
            driver = AXIL_Driver::type_id::create("driver", this);
        end
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
    function AXIL_Protocol_Checker get_protocol_checker();
        return protocol_checker;
    endfunction
endclass
