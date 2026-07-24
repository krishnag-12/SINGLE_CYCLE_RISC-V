`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_top;
    import uvm_pkg::*;
    import riscv_pkg::*;

    logic clk;

    // Interface
    riscv_if vif(clk);

    // DUT
    single_cycle_riscv dut(
        .clk(clk),
        .rst(vif.rst)
    );

    // Bind internal signals to interface
    assign vif.pc = dut.PC_top;
    assign vif.instr = dut.RD_inst;
    assign vif.reg_write = dut.RegWrite_top;
    assign vif.write_reg_addr = dut.RD_inst[11:7]; // rd
    assign vif.write_data = dut.reg_write_data;
    assign vif.mem_write = dut.MemWrite_top;
    assign vif.alu_result = dut.alu_result_top;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // UVM start
    initial begin
        // Set virtual interface in config_db
        uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", vif);
        
        // Preload memory
        $readmemh("program.mem.txt", dut.inst_mem.mem);
        
        // Run test
        run_test("riscv_base_test");
    end

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end
endmodule
