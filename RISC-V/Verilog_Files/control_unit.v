`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Krishna Gupta
// Design Name: Control Unit
// Module Name: control_unit
// Project Name: RISC-V Processor
//////////////////////////////////////////////////////////////////////////////////
`include "ALU_decoder.v"
`include "main_decoder.v"

module control_unit(
    input  [6:0] op,        // 7-bit opcode from the instruction
    input  [6:0] funct7,    // 7-bit funct7 field from the instruction
    input  [2:0] funct3,    // 3-bit funct3 field from the instruction
    output wire RegWrite,   // Register Write enable signal
    output wire ALUSrc,     // ALU Source select (1: immediate, 0: register)
    output wire MemWrite,   // Memory Write enable signal
    output wire ResultSrc,  // Selects between ALU result or memory read data
    output wire Branch,     // Branch signal for control logic
    output wire [1:0] ImmSrc,   // Immediate type selector
    output wire [2:0] alu_ctrl  // ALU control signals (from ALU_decoder)
);

    // Internal wire to connect ALUOp between main_decoder and ALU_decoder
    wire [1:0] ALUOp;

    // Instantiate main decoder
    main_decoder m1 (
        .op(op),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp),
        .Branch(Branch)
    );

    // ALU_decoder requires bit 5 of opcode - extract it
    wire op5;
    assign op5 = op[5];

    // Instantiate ALU decoder
    ALU_decoder a1 (
        .op5(op5),
        .funct7(funct7[5]),   // Assuming bit 5 is the intended part
        .ALUOp(ALUOp),
        .funct3(funct3),
        .alu_ctrl(alu_ctrl)
    );

endmodule
