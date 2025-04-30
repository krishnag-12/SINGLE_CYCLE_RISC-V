`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Single Cycle RISC-V Top Module
// Module Name: single_cycle_riscv
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

`include "program_counter.v"
`include "instruction_memory.v"
`include "register_file.v"
`include "sign_extender.v"
`include "alu.v"
`include "control_unit.v"
`include "data_memory.v"
`include "pc_adder.v"

module single_cycle_riscv(
    input clk,         // Clock signal
    input rst          // Reset signal
);

// === Wire Declarations ===
wire [31:0] PC_top;              // Current Program Counter value
wire [31:0] PCplus4;             // PC + 4 value
wire [31:0] RD_inst;             // Instruction from instruction memory
wire [31:0] RD1_top, RD2_top;    // Register file read outputs
wire [31:0] Imm_ext_top;         // Sign-extended immediate
wire [31:0] alu_result_top;      // ALU result
wire [31:0] ReadData;            // Data read from data memory
wire [2:0] alu_ctrl_top;         // ALU control signals
wire [1:0] ImmSrc_top;           // Immediate source control
wire ALUSrc_top, MemWrite_top, ResultSrc_top, Branch_top, RegWrite_top; // Control signals

// === Program Counter ===
program_counter pc(
    .clk(clk),
    .rst(rst),
    .PC(PC_top),
    .PC_NEXT(PCplus4)
);

// === PC + 4 Adder ===
pc_adder pcadd(
    .a(PC_top),
    .b(32'd4),
    .c(PCplus4)
);

// === Instruction Memory ===
instruction_memory inst_mem(
    .rst(rst),
    .A(PC_top),
    .RD(RD_inst)
);

// === Register File ===
register_file rg_file(
    .clk(clk),
    .rst(rst),
    .A1(RD_inst[19:15]),        // rs1
    .A2(RD_inst[24:20]),        // rs2
    .A3(RD_inst[11:7]),         // rd
    .WD3(ReadData),             // Write data
    .WE3(RegWrite_top),         // Write enable
    .RD1(RD1_top),              // Read data 1
    .RD2(RD2_top)               // Read data 2
);

// === Sign Extender ===
sign_extender sign_ex(
    .in(RD_inst),
    .ImmSrc(ImmSrc_top),
    .Imm_ext(Imm_ext_top)
);

// === ALU ===
alu alu(
    .A(RD1_top),
    .B(ALUSrc_top ? Imm_ext_top : RD2_top),  // ALU second operand is immediate or register
    .alu_ctrl(alu_ctrl_top),
    .result(alu_result_top),
    .Z(), .N(), .V(), .C() // ALU flags (optional, unused here)
);

// === Control Unit ===
control_unit control_unit(
    .op(RD_inst[6:0]),
    .funct7(RD_inst[31:25]),
    .funct3(RD_inst[14:12]),
    .RegWrite(RegWrite_top),
    .ALUSrc(ALUSrc_top),
    .MemWrite(MemWrite_top),
    .ResultSrc(ResultSrc_top),
    .Branch(Branch_top),
    .ImmSrc(ImmSrc_top),
    .alu_ctrl(alu_ctrl_top)
);

// === Data Memory ===
data_memory data_mem(
    .A(alu_result_top),
    .WD(RD2_top),         // Data to be written to memory
    .clk(clk),
    .rst(rst),
    .WE(MemWrite_top),    // Write enable
    .RD(ReadData)         // Read data output
);

endmodule

module single_cycle_riscv_tb;

    // Inputs
    reg clk;
    reg rst;

    // Instantiate the DUT (Device Under Test)
    single_cycle_riscv uut (
        .clk(clk),
        .rst(rst)
    );

    // Clock Generation: Toggle every 5 ns -> 10 ns clock period
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;

        $display("Time\tclk\trst");
        $monitor("%g\t%b\t%b", $time, clk, rst);

        // Apply reset
        #10;
        rst = 0;  // Assert reset (active low if your logic follows that)
        #10;
        rst = 1;  // Deassert reset

        // Run simulation for some cycles
        #100;

        // Finish simulation
        $finish;
    end

endmodule