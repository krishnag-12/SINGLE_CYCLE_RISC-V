`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Program Counter Adder
// Module Name: pc_adder
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module pc_adder(
    input [31:0] a,    // First 32-bit input (usually current PC)
    input [31:0] b,    // Second 32-bit input (typically 4 or branch offset)
    output [31:0] c    // Output: sum of inputs a and b
);

// Perform 32-bit addition
assign c = a + b;

endmodule
