`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Control Unit
// Module Name: main_decoder
// Project Name: RISC-V Processor
// 
//////////////////////////////////////////////////////////////////////////////////


module main_decoder(
    input zero,           // Zero flag, used for branch decision
    input [6:0] op,       // 7-bit opcode
    output reg RegWrite,   // Register write control signal
    output reg MemWrite,   // Memory write control signal
    output reg ResultSrc,  // Result source control signal
    output reg ALUSrc,     // ALU source control signal
    output reg PCSrc,      // PC source control signal for branching
    output reg [1:0] ImmSrc,  // Immediate source control signals
    output reg [1:0] ALUOp    // ALU operation control signals
    );

    reg branch;  // Branch signal (local register)

    always @(*) begin
        // Default values (for any undefined op code)
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        ResultSrc = 1'b0;
        ALUSrc = 1'b0;
        branch = 1'b0;
        ALUOp = 2'b00;
        ImmSrc = 2'b00;

        // Check op code and configure control signals accordingly
        casex (op)
            7'b0000011: begin  // Load instruction (e.g., LW)
                RegWrite = 1'b1;      // Enable register write
                ImmSrc = 2'b00;       // Immediate source (likely sign-extended)
                ALUSrc = 1'b1;        // ALU uses immediate
                MemWrite = 1'b0;      // No memory write
                ResultSrc = 1'b1;     // Result comes from memory
                branch = 1'b0;        // Not a branch instruction
                ALUOp = 2'b00;        // ALU operation (add for address calculation)
            end
            7'b0100011: begin  // Store instruction (e.g., SW)
                RegWrite = 1'b0;      // No register write
                ImmSrc = 2'b01;       // Immediate source for offset
                ALUSrc = 1'b1;        // ALU uses immediate
                MemWrite = 1'b1;      // Enable memory write
                ResultSrc = 1'bx;     // Don't care, since no register write
                branch = 1'b0;        // Not a branch instruction
                ALUOp = 2'b00;        // ALU operation (add for address calculation)
            end
            7'b0110011: begin  // R-type instruction (e.g., ADD, SUB)
                RegWrite = 1'b1;      // Enable register write
                ImmSrc = 2'bxx;       // Don't care (no immediate for R-type)
                ALUSrc = 1'b0;        // ALU does not use immediate
                MemWrite = 1'b0;      // No memory write
                ResultSrc = 1'b0;     // Result comes from ALU
                branch = 1'b0;        // Not a branch instruction
                ALUOp = 2'b10;        // ALU operation (defined by funct field)
            end
            7'b1100011: begin  // Branch instruction (e.g., BEQ)
                RegWrite = 1'b0;      // No register write
                ImmSrc = 2'b10;       // Immediate is used for branch offset
                ALUSrc = 1'b0;        // ALU does not use immediate
                MemWrite = 1'b0;      // No memory write
                ResultSrc = 1'bx;     // Don't care, as no result written to register
                branch = 1'b1;        // This is a branch instruction
                ALUOp = 2'b01;        // ALU operation (used for branch condition)
            end
            default: begin
                // Default case for unsupported op codes (handles undefined behavior)
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'b0;
                ALUSrc = 1'b0;
                branch = 1'b0;
                ALUOp = 2'b00;
                ImmSrc = 2'b00;
            end
        endcase

        // PCSrc is used to decide if the program counter should be updated
        // Branch occurs when the 'branch' signal is set and 'zero' flag is active
        PCSrc = branch & zero;  // PC is updated if it is a branch and zero flag is active
    end
endmodule

module tb_main_decoder;

    // Declare testbench signals
    reg zero;            // Zero flag input
    reg [6:0] op;        // Opcode input
    wire RegWrite;       // Register write output
    wire MemWrite;       // Memory write output
    wire ResultSrc;      // Result source output
    wire ALUSrc;         // ALU source output
    wire PCSrc;          // PC source output
    wire [1:0] ImmSrc;   // Immediate source output
    wire [1:0] ALUOp;    // ALU operation output

    // Instantiate the main_decoder module
    main_decoder uut (
        .zero(zero),
        .op(op),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .PCSrc(PCSrc),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );

    // Test sequence
    initial begin
        // Initialize inputs
        zero = 0;
        op = 7'b0000011;  // Test load instruction (LW)

        // Display results for each test case
        $display("Test Case 1: op = 7'b0000011 (LW)");
        $monitor("RegWrite = %b, MemWrite = %b, ResultSrc = %b, ALUSrc = %b, PCSrc = %b, ImmSrc = %b, ALUOp = %b", 
                 RegWrite, MemWrite, ResultSrc, ALUSrc, PCSrc, ImmSrc, ALUOp);
        #10;

        op = 7'b0100011;  // Test store instruction (SW)
        $display("Test Case 2: op = 7'b0100011 (SW)");
        #10;

        op = 7'b0110011;  // Test R-type instruction (e.g., ADD)
        $display("Test Case 3: op = 7'b0110011 (R-type)");
        #10;

        op = 7'b1100011;  // Test branch instruction (e.g., BEQ)
        $display("Test Case 4: op = 7'b1100011 (BEQ)");
        zero = 1;  // Set zero flag to simulate branch taken
        #10;

        // Test default case (undefined op code)
        op = 7'b1111111;
        $display("Test Case 5: op = 7'b1111111 (Undefined op code)");
        #10;

        // End simulation
        $finish;
    end

endmodule
