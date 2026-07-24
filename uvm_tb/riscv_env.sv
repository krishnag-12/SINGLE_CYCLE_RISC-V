class riscv_env extends uvm_env;
    `uvm_component_utils(riscv_env)
    
    riscv_agent      agent;
    riscv_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = riscv_agent::type_id::create("agent", this);
        scb = riscv_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scb.item_collected_export);
    endfunction
endclass
