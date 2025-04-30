`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Sign Extenser
// Module sign_extender
// Project Name: RISC-V Processor
// 
//////////////////////////////////////////////////////////////////////////////////


module sign_extender(
    input [31:0] in,
    output [31:0] Imm_ext
    );
    assign Imm_ext = (in[31]) ? {{20{1'b1}}, in[31:20]} : {{20{1'b0}}, in[31:20]};
endmodule
