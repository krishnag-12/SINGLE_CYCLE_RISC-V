class riscv_driver extends uvm_driver#(riscv_seq_item);
    `uvm_component_utils(riscv_driver)
    
    virtual riscv_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.rst <= 1;
        forever begin
            seq_item_port.get_next_item(req);
            vif.rst <= req.rst;
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
endclass
