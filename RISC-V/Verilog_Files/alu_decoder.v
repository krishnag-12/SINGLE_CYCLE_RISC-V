`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
//
// Design Name: ALU Decoder
// Module Name: ALU_decoder
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module ALU_decoder(
    input [6:0] op,           // 7-bit opcode
    input [6:0] funct7,       // 7-bit funct7 field from instruction
    input [2:0] funct3,       // 3-bit funct3 field from instruction
    input [1:0] ALUOp,        // ALU operation signal from main decoder
    output reg [2:0] alu_ctrl // Output control signal to ALU
);

    always @(*) begin
        case (ALUOp)
            2'b00: alu_ctrl = 3'b000; // For load/store -> ALU does addition
            2'b01: alu_ctrl = 3'b001; // For branch -> ALU does subtraction
            2'b10: begin              // R-type and I-type
                case ({funct7, funct3})
                    10'b0000000_000: alu_ctrl = 3'b000; // ADD
                    10'b0100000_000: alu_ctrl = 3'b001; // SUB
                    10'b0000000_111: alu_ctrl = 3'b010; // AND
                    10'b0000000_110: alu_ctrl = 3'b011; // OR
                    10'b0000000_100: alu_ctrl = 3'b100; // XOR
                    10'b0000000_010: alu_ctrl = 3'b101; // SLT
                    default:         alu_ctrl = 3'b000; // Default to ADD
                endcase
            end
            default: alu_ctrl = 3'b000; // Safe default
        endcase
    end

endmodule
