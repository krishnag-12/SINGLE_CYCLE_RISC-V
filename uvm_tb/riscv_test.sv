class riscv_base_test extends uvm_test;
    `uvm_component_utils(riscv_base_test)
    
    riscv_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = riscv_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        reset_seq seq;
        phase.raise_objection(this);
        
        seq = reset_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        // Wait for execution
        #500;
        
        phase.drop_objection(this);
    endtask
endclass
