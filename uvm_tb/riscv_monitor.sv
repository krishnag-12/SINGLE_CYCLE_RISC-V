class riscv_monitor extends uvm_monitor;
    `uvm_component_utils(riscv_monitor)
    
    virtual riscv_if vif;
    uvm_analysis_port#(riscv_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction

    virtual task run_phase(uvm_phase phase);
        riscv_seq_item item;
        item = riscv_seq_item::type_id::create("item");
        forever begin
            @(posedge vif.clk);
            #1; // Sample after clock edge
            item.rst = vif.rst;
            item.pc = vif.pc;
            item.instr = vif.instr;
            item.reg_write = vif.reg_write;
            item.write_reg_addr = vif.write_reg_addr;
            item.write_data = vif.write_data;
            item.mem_write = vif.mem_write;
            item.alu_result = vif.alu_result;
            ap.write(item);
        end
    endtask
endclass
