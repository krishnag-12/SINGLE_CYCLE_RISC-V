class riscv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(riscv_scoreboard)
    
    uvm_analysis_imp#(riscv_seq_item, riscv_scoreboard) item_collected_export;
    
    int instr_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write(riscv_seq_item item);
        if (item.rst == 1) begin
            // Check based on the loaded program behavior
            `uvm_info("SCB", $sformatf("PC: %0h | Instr: %0h | RegWrite: %b | Addr: %0d | Data: %0d", 
                      item.pc, item.instr, item.reg_write, item.write_reg_addr, item.write_data), UVM_LOW)
            instr_count++;
            
            // Basic checks for the specific program.mem.txt values
            if (item.pc == 32'h00000000 && item.reg_write) begin
                if (item.write_data !== 10) `uvm_error("SCB_FAIL", "x1 should be 10")
            end
            if (item.pc == 32'h00000008 && item.reg_write) begin
                if (item.write_data !== 30) `uvm_error("SCB_FAIL", "x3 should be 30")
            end
            
            if (item.instr == 32'h00000063) begin
                `uvm_info("SCB_DONE", "Infinite loop (halt) detected.", UVM_NONE)
            end
        end
    endfunction
endclass
