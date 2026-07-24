interface riscv_if(input logic clk);
    logic rst;
    
    // Probed internal signals
    logic [31:0] pc;
    logic [31:0] instr;
    logic        reg_write;
    logic [4:0]  write_reg_addr;
    logic [31:0] write_data;
    logic        mem_write;
    logic [31:0] alu_result;
endinterface
