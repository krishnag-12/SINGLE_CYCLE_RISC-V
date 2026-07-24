class riscv_seq_item extends uvm_sequence_item;
    rand logic rst;
    
    logic [31:0] pc;
    logic [31:0] instr;
    logic        reg_write;
    logic [4:0]  write_reg_addr;
    logic [31:0] write_data;
    logic        mem_write;
    logic [31:0] alu_result;

    `uvm_object_utils_begin(riscv_seq_item)
        `uvm_field_int(rst, UVM_ALL_ON)
        `uvm_field_int(pc, UVM_ALL_ON)
        `uvm_field_int(instr, UVM_ALL_ON)
        `uvm_field_int(reg_write, UVM_ALL_ON)
        `uvm_field_int(write_reg_addr, UVM_ALL_ON)
        `uvm_field_int(write_data, UVM_ALL_ON)
        `uvm_field_int(mem_write, UVM_ALL_ON)
        `uvm_field_int(alu_result, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "riscv_seq_item");
        super.new(name);
    endfunction
endclass
