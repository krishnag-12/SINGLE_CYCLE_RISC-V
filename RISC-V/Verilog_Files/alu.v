`timescale 1ns / 1ps
//`include "ALU_decoder.v"
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Arithmetic Logic Unit
// Module Name: ALU
// Project Name: RISC-V Processor
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input [31:0] A, B,     // 32-bit input operands A and B
    input [2:0] alu_ctrl,   // 3-bit ALU control signal to determine the operation
    output reg [31:0] result, // 32-bit output result of the ALU operation
    output reg Z, N, V, C    // Z- zero flag, N- negative flag, V- overflow flag, C- carry flag
    );
    
    reg [32:0] sum;  // 33-bit register to hold the sum, which includes the carry out
    
    // Always block triggered whenever there's a change in inputs A, B, or alu_ctrl
    always @(*) begin
        // Reset the flags at the beginning of the always block
        Z = 0;
        N = 0;
        V = 0;
        C = 0;
        
        // ALU operation selection based on alu_ctrl
        case(alu_ctrl)
            3'b000: begin
                result = A + B;   // Perform addition if alu_ctrl is 000
                sum = A + B;      // Calculate sum for carry and overflow detection
            end
            3'b001: begin
                result = A - B;   // Perform subtraction if alu_ctrl is 001
                sum = A - B;      // Calculate sum for carry and overflow detection
            end
            3'b010: begin
                result = A * B;   // Perform multiplication if alu_ctrl is 010
                sum = A * B;      // Multiplication doesn't directly affect carry/overflow here
            end
            3'b011: begin
                result = A / B;   // Perform division if alu_ctrl is 011
                sum = A / B;      // Division doesn't directly affect carry/overflow here
            end
            3'b100: begin
                result = A & B;   // Perform bitwise AND if alu_ctrl is 100
                sum = A & B;      // Bitwise AND doesn't affect carry/overflow here
            end
            3'b101: begin
                result = A | B;   // Perform bitwise OR if alu_ctrl is 101
                sum = A | B;      // Bitwise OR doesn't affect carry/overflow here
            end
            3'b110: begin
                result = A ^ B;   // Perform bitwise XOR if alu_ctrl is 110
                sum = A ^ B;      // Bitwise XOR doesn't affect carry/overflow here
            end
            3'b111: begin
                result = A ~^ B;  // Perform bitwise XNOR if alu_ctrl is 111
                sum = A ~^ B;     // Bitwise XNOR doesn't affect carry/overflow here
            end
            default: begin
                result = 0;       // Default case to avoid latches
                sum = 0;          // Default sum
            end
        endcase

        // Set the Zero flag (Z) if the result is 0
        if (result == 0) 
            Z = 1'b1;

        // Set the Negative flag (N) based on the MSB of the result (signed value)
        N = result[31]; 

        // Set the Carry flag (C) based on the 33rd bit of the sum
        // Carry flag is set when there's a carry out from the MSB during addition or subtraction
        if (sum[32] == 1) begin
            C = 1'b1;  // Carry occurred
        end

        // Set the Overflow flag (V) based on the overflow condition
        // For addition: overflow occurs if the signs of operands are the same but the result sign is different
        if (alu_ctrl == 3'b000) begin  // Addition operation
            if ((A[31] == B[31]) && (result[31] != A[31])) begin
                V = 1'b1;  // Overflow occurred in addition
            end
        end
        
        // For subtraction: overflow occurs if the signs of operands are different but the result sign is incorrect
        if (alu_ctrl == 3'b001) begin  // Subtraction operation
            if ((A[31] != B[31]) && (result[31] != A[31])) begin
                V = 1'b1;  // Overflow occurred in subtraction
            end
        end
    end

endmodule


module alu_tb;

    // Declare the inputs as reg and outputs as wire
    reg [31:0] A, B;        // 32-bit operands A and B
    reg [2:0] alu_ctrl;     // 3-bit ALU control signal to determine the operation
    wire [31:0] result;     // 32-bit ALU result
    wire Z, N, V, C;        // Flags for Zero, Negative, Overflow, and Carry

    // Instantiate the ALU module
    alu uut (
        .A(A),
        .B(B),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .Z(Z),
        .N(N),
        .V(V),
        .C(C)
    );

    // Testbench procedure to apply test cases
    initial begin
        // Monitor the inputs and results
        $monitor("A = %d, B = %d, alu_ctrl = %b, result = %d, Z = %b, N = %b, V = %b, C = %b", A, B, alu_ctrl, result, Z, N, V, C);

        // Test Case 1: ALU ADD (000)
        A = 32'd15; B = 32'd10; alu_ctrl = 3'b000; // 15 + 10 = 25
        #10;

        // Test Case 2: ALU SUBTRACT (001)
        A = 32'd20; B = 32'd5; alu_ctrl = 3'b001; // 20 - 5 = 15
        #10;

        // Test Case 3: ALU MULTIPLY (010)
        A = 32'd6; B = 32'd7; alu_ctrl = 3'b010; // 6 * 7 = 42
        #10;

        // Test Case 4: ALU DIVIDE (011)
        A = 32'd40; B = 32'd8; alu_ctrl = 3'b011; // 40 / 8 = 5
        #10;

        // Test Case 5: ALU AND (100)
        A = 32'b10101010101010101010101010101010; B = 32'b11001100110011001100110011001100; alu_ctrl = 3'b100; // AND operation
        #10;

        // Test Case 6: ALU OR (101)
        A = 32'b10101010101010101010101010101010; B = 32'b11001100110011001100110011001100; alu_ctrl = 3'b101; // OR operation
        #10;

        // Test Case 7: ALU XOR (110)
        A = 32'b10101010101010101010101010101010; B = 32'b11001100110011001100110011001100; alu_ctrl = 3'b110; // XOR operation
        #10;

        // Test Case 8: ALU XNOR (111)
        A = 32'b10101010101010101010101010101010; B = 32'b11001100110011001100110011001100; alu_ctrl = 3'b111; // XNOR operation
        #10;

        // Test Case 9: Zero result (Z flag)
        A = 32'd0; B = 32'd0; alu_ctrl = 3'b000; // 0 + 0 = 0
        #10;

        // Test Case 10: Negative result (N flag)
        A = 32'd5; B = 32'd10; alu_ctrl = 3'b001; // 5 - 10 = -5 (Negative result)
        #10;

        // Test Case 11: Overflow (V flag) in addition
        A = 32'h7FFFFFFF; B = 32'h1; alu_ctrl = 3'b000; // 2147483647 + 1 = Overflow
        #10;

        // Test Case 12: Carry flag
        A = 32'hFFFFFFFF; B = 32'h1; alu_ctrl = 3'b000; // Carry in addition (FFFF + 1)
        #10;

        // End the simulation after all tests
        $finish;
    end

endmodule
