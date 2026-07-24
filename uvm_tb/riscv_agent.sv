class riscv_agent extends uvm_agent;
    `uvm_component_utils(riscv_agent)
    
    riscv_driver    driver;
    riscv_sequencer sequencer;
    riscv_monitor   monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = riscv_driver::type_id::create("driver", this);
        sequencer = riscv_sequencer::type_id::create("sequencer", this);
        monitor = riscv_monitor::type_id::create("monitor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
