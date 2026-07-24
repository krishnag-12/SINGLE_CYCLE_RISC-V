`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Single Cycle RISC-V Top Module (Corrected)
// Module Name: single_cycle_riscv
// Project Name: RISC-V Processor
//
// FIXES:
// 1. Added PC-Next MUX and Branch Target Adder for branch logic.
// 2. Added Register File Write-Back MUX (ResultSrc).
// 3. Standardized all modules to use ACTIVE-LOW reset (rst = 0 to reset).
//
//////////////////////////////////////////////////////////////////////////////////

//================================================================
// Top-Level Module: single_cycle_riscv
//================================================================
module single_cycle_riscv(
    input clk,        // Clock signal
    input rst         // Reset signal (ACTIVE-LOW)
);

// === Wire Declarations ===
wire [31:0] PC_top;          // Current Program Counter value
wire [31:0] PCplus4;         // PC + 4 value
wire [31:0] RD_inst;         // Instruction from instruction memory
wire [31:0] RD1_top, RD2_top;  // Register file read outputs
wire [31:0] Imm_ext_top;     // Sign-extended immediate
wire [31:0] alu_result_top;  // ALU result
wire [31:0] ReadData;        // Data read from data memory
wire [2:0] alu_ctrl_top;    // ALU control signals
wire [1:0] ImmSrc_top;      // Immediate source control
wire Z_top;                 // Zero flag from ALU
wire ALUSrc_top, MemWrite_top, ResultSrc_top, Branch_top, RegWrite_top; // Control signals

// --- NEW Wires for fixed logic ---
wire [31:0] branch_target_addr; // Result of PC + Imm_ext
wire [31:0] pc_next_out;        // Input to PC module (from MUX)
wire [31:0] reg_write_data;     // Input to Register File (from MUX)


// === Program Counter ===
// Note: This module implements an active-low synchronous reset
program_counter pc(
    .clk(clk),
    .rst(rst),
    .PC_NEXT(pc_next_out), // <-- Connect to MUX output
    .PC(PC_top)            // <-- Port order
);

// === PC + 4 Adder ===
pc_adder pcadd(
    .a(PC_top),
    .b(32'd4),
    .c(PCplus4)
);

// --- Branch Target Adder (PC + immediate) ---
pc_adder branch_addr_adder (
    .a(PC_top),
    .b(Imm_ext_top),
    .c(branch_target_addr)
);

// --- PC-Next MUX (Selects PC+4 or Branch Target) ---
// Branch_top is the 'PCSrc' signal from main_decoder (branch & zero)
assign pc_next_out = Branch_top ? branch_target_addr : PCplus4;


// === Instruction Memory ===
// Note: Reset is removed. ROMs are not typically reset.
// The PC resetting to 0 handles fetching the first instruction.
instruction_memory inst_mem(
    .A(PC_top),
    .RD(RD_inst)
);

// --- Register Write-Back MUX ---
// ResultSrc: 0 = ALU Result, 1 = Memory ReadData
assign reg_write_data = ResultSrc_top ? ReadData : alu_result_top;


// === Register File ===
// Note: Now has a synchronous active-low reset
register_file rg_file(
    .clk(clk),
    .rst(rst),
    .A1(RD_inst[19:15]),     // rs1
    .A2(RD_inst[24:20]),     // rs2
    .A3(RD_inst[11:7]),      // rd
    .WD3(reg_write_data),    // <-- Connect to MUX output
    .WE3(RegWrite_top),      // Write enable
    .RD1(RD1_top),           // Read data 1
    .RD2(RD2_top)            // Read data 2
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
    .B(ALUSrc_top ? Imm_ext_top : RD2_top),  // ALU second operand
    .alu_ctrl(alu_ctrl_top),
    .result(alu_result_top),
    .Z(Z_top), // <-- Connected Zero flag
    .N(),      // Negative flag (available for BLT)
    .V(),      // Overflow
    .C()       // Carry
);

// === Control Unit ===
control_unit control_unit(
    .op(RD_inst[6:0]),
    .funct7(RD_inst[31:25]),
    .funct3(RD_inst[14:12]),
    .zero(Z_top), // <-- Added zero flag input
    .RegWrite(RegWrite_top),
    .ALUSrc(ALUSrc_top),
    .MemWrite(MemWrite_top),
    .ResultSrc(ResultSrc_top),
    .Branch(Branch_top),
    .ImmSrc(ImmSrc_top),
    .alu_ctrl(alu_ctrl_top)
);

// === Data Memory ===
// Note: Reset logic is now synchronous active-low
data_memory data_mem(
    .A(alu_result_top),
    .WD(RD2_top),        // Data to be written to memory
    .clk(clk),
    .rst(rst),
    .WE(MemWrite_top),   // Write enable
    .RD(ReadData)        // Read data output
);

endmodule

//================================================================
//                  Component Modules
//================================================================

// --- ALU (Arithmetic Logic Unit) ---
// FIXED: Removed non-synthesizable MUL/DIV.
// FIXED: Added SLT/SLTU (Set Less Than / Unsigned) for branches.
module alu(
    input [31:0] A, B,      // 32-bit input operands A and B
    input [2:0] alu_ctrl,   // 3-bit ALU control signal
    output reg [31:0] result, // 32-bit output result
    output reg Z, N, V, C   // Flags
    );
    
    reg [32:0] sum;  // 33-bit register for carry/overflow
    
    // --- FIX for Synthesis Error ---
    // Pre-calculate unsigned carry/borrow for older synthesizers
    wire [32:0] unsigned_add_result = {1'b0, A} + {1'b0, B};
    wire [32:0] unsigned_sub_result = {1'b0, A} - {1'b0, B};
    // -----------------------------
    
    always @(*) begin
        // Reset flags
        Z = 1'b0;
        N = 1'b0;
        V = 1'b0;
        C = 1'b0;
        
        // Default sum and result
        sum = 33'h000000000;
        result = 32'h00000000;
        
        case(alu_ctrl)
            3'b000: begin // ADD
                sum = {A[31], A} + {B[31], B}; // Sign-extend for overflow check
                result = A + B;
            end
            3'b001: begin // SUB
                sum = {A[31], A} - {B[31], B}; // Sign-extend for overflow check
                result = A - B;
            end
            3'b010: begin // SLT (Set Less Than, signed)
                result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
                sum = {1'b0, result};
            end
            3'b011: begin // SLTU (Set Less Than, unsigned)
                result = (A < B) ? 32'd1 : 32'd0;
                sum = {1'b0, result};
            end
            3'b100: begin // AND
                result = A & B;
                sum = {1'b0, result};
            end
            3'b101: begin // OR
                result = A | B;
                sum = {1'b0, result};
            end
            3'b110: begin // XOR
                result = A ^ B;
                sum = {1'b0, result};
            end
            3'b111: begin // (Unused)
                result = 32'h00000000;
                sum = 33'h000000000;
            end
            default: begin
                result = 32'h00000000;
                sum = 33'h000000000;
            end
        endcase

        // Set Zero flag
        if (result == 32'h00000000) 
            Z = 1'b1;

        // Set Negative flag
        N = result[31]; 

        // Set Carry flag (for unsigned)
        // For ADD:
        if (alu_ctrl == 3'b000) begin
             // Carry out for unsigned addition
            C = unsigned_add_result[32]; // <-- SYNTAX FIX
        end
        // For SUB:
        if (alu_ctrl == 3'b001) begin
             // Borrow for unsigned subtraction
             C = unsigned_sub_result[32]; // <-- SYNTAX FIX
        end
        
        // Set Overflow flag (for signed)
        // Overflow occurs if (A_sign == B_sign) AND (Result_sign != A_sign)
        if (alu_ctrl == 3'b000) begin  // Addition
            if ((A[31] == B[31]) && (result[31] != A[31])) begin
                V = 1'b1;
            end
        end
        
        if (alu_ctrl == 3'b001) begin  // Subtraction
            if ((A[31] != B[31]) && (result[31] != A[31])) begin
                V = 1'b1;
            end
        end
    end
endmodule

// --- ALU Decoder ---
// FIXED: Mapped R-type and I-type funct codes to the new ALU.
module ALU_decoder(
    input [6:0] op,         // 7-bit opcode
    input [6:0] funct7,     // 7-bit funct7 field
    input [2:0] funct3,     // 3-bit funct3 field
    input [1:0] ALUOp,      // ALU operation signal from main decoder
    output reg [2:0] alu_ctrl // Output control signal to ALU
);

    always @(*) begin
        // Default to ADD
        alu_ctrl = 3'b000; 
        
        case (ALUOp)
            2'b00: alu_ctrl = 3'b000; // For load/store -> ALU does addition
            2'b01: alu_ctrl = 3'b001; // For branch (BEQ/BNE) -> ALU does subtraction
            // 2'b01 could also be SLT/SLTU for other branches,
            // but main_decoder needs to be updated.
            
            2'b10: begin             // R-type or I-type
                if (op == 7'b0110011) begin // R-type
                    case ({funct7, funct3})
                        // R-Type
                        10'b0000000_000: alu_ctrl = 3'b000; // ADD
                        10'b0100000_000: alu_ctrl = 3'b001; // SUB
                        10'b0000000_010: alu_ctrl = 3'b010; // SLT
                        10'b0000000_011: alu_ctrl = 3'b011; // SLTU
                        10'b0000000_100: alu_ctrl = 3'b110; // XOR
                        10'b0000000_110: alu_ctrl = 3'b101; // OR
                        10'b0000000_111: alu_ctrl = 3'b100; // AND
                        default: alu_ctrl = 3'b000; // Default R-type
                    endcase
                end 
                else if (op == 7'b0010011) begin // I-type
                    case (funct3)
                        3'b000: alu_ctrl = 3'b000; // ADDI
                        3'b010: alu_ctrl = 3'b010; // SLTI
                        3'b011: alu_ctrl = 3'b011; // SLTIU
                        3'b100: alu_ctrl = 3'b110; // XORI
                        3'b110: alu_ctrl = 3'b101; // ORI
                        3'b111: alu_ctrl = 3'b100; // ANDI
                        // SLLI, SRLI, SRAI (funct7) would go here too
                        default: alu_ctrl = 3'b000; // Default I-type
                    endcase
                end
                // Other opcodes might also set ALUOp=2'b10 (e.g., LUI, AUIPC)
                // but they don't need a specific ALU operation.
            end
            default: alu_ctrl = 3'b000; // Safe default
        endcase
    end
endmodule

// --- Control Unit (Main) ---
module control_unit(
    input  [6:0] op,        // 7-bit opcode
    input  [6:0] funct7,    // 7-bit funct7 field
    input  [2:0] funct3,    // 3-bit funct3 field
    input  zero,            // <-- FIXED: Added zero flag input
    output wire RegWrite,   // Register Write enable
    output wire ALUSrc,     // ALU Source select
    output wire MemWrite,   // Memory Write enable
    output wire ResultSrc,  // Selects ALU result or memory read
    output wire Branch,     // Branch signal (renamed from PCSrc)
    output wire [1:0] ImmSrc, // Immediate type selector
    output wire [2:0] alu_ctrl // ALU control signals
);

    // Internal wire to connect ALUOp
    wire [1:0] ALUOp;

    // Instantiate main decoder
    main_decoder m1 (
        .zero(zero),        // <-- FIXED: Connected zero flag
        .op(op),
        //.funct3(funct3), // <-- Pass funct3 for advanced branch logic
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .PCSrc(Branch),     // <-- FIXED: Port name was PCSrc, not Branch
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );

    // Instantiate ALU decoder
    ALU_decoder a1 (
        .op(op),            // <-- FIXED: Pass full opcode
        .funct7(funct7),    // <-- FIXED: Pass full funct7
        .ALUOp(ALUOp),
        .funct3(funct3),
        .alu_ctrl(alu_ctrl)
    );
endmodule

// --- Data Memory ---
// FIXED: Changed reset to synchronous active-low
// FIXED: Removed non-synthesizable 'for' loop from reset
module data_memory(
    input [31:0] A,         // Address input (Byte Address)
    input [31:0] WD,        // Write Data input
    input clk,              // Clock
    input rst,              // Asynchronous Reset (ACTIVE-LOW)
    input WE,               // Write Enable
    output [31:0] RD        // Read Data output
);

    // Declare memory array of 1024 32-bit registers (4KB)
    reg [31:0] data_mem [1023:0];
    
    // Calculate word address (A[11:2])
    // NOTE: For LB/LH/SB/SH, you would use A[1:0] and funct3
    wire [9:0] word_addr = A[11:2];

    // Asynchronous read logic
    assign RD = data_mem[word_addr];

    // Write and reset logic (synchronous)
    always @(posedge clk) begin
        if (!rst) begin 
            // On reset, memory content is typically not zeroed by logic.
            // It is loaded from a file during synthesis (e.g., $readmemh).
            // A 'for' loop here is not synthesizable to BRAM.
        end else if (WE) begin
            // On write enable, write data to word address
            data_mem[word_addr] <= WD;
        end
    end
endmodule

// --- Instruction Memory (ROM) ---
// FIXED: Removed reset. ROMs are read-only and don't have resets.
module instruction_memory(
    input [31:0] A,     // Address input (Byte Address)
    output [31:0] RD    // Instruction output (Read Data)
    );

    // 1024 x 32-bit memory array (4KB)
    // Use 'initial $readmemh("program.mem", mem);' to load a program
    reg [31:0] mem [1023:0];
    
    // Calculate word address (A[11:2])
    wire [9:0] word_addr = A[11:2];

    // Combinational read.
    assign RD = mem[word_addr];

endmodule

// --- Main Decoder ---
module main_decoder(
    input zero,         // Zero flag
    input [6:0] op,     // 7-bit opcode
    // input [2:0] funct3, // <-- Add this to decode BNE, BLT, etc.
    output reg RegWrite,  // Register write
    output reg MemWrite,  // Memory write
    output reg ResultSrc, // Result source
    output reg ALUSrc,    // ALU source
    output reg PCSrc,     // PC source for branching
    output reg [1:0] ImmSrc, // Immediate source
    output reg [1:0] ALUOp   // ALU operation
    );

    reg branch;  // Local branch signal

    always @(*) begin
        // Default values
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        ResultSrc = 1'b0; // Default to ALU result
        ALUSrc = 1'b0;    // Default to Register Read 2
        branch = 1'b0;
        ALUOp = 2'b00;
        ImmSrc = 2'b00;

        case (op)
            7'b0000011: begin  // Load (e.g., LW)
                RegWrite = 1'b1;
                ImmSrc = 2'b00;      // I-type
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                ResultSrc = 1'b1;    // Result from memory
                branch = 1'b0;
                ALUOp = 2'b00;       // ALU does add
            end
            7'b0100011: begin  // Store (e.g., SW)
                RegWrite = 1'b0;
                ImmSrc = 2'b01;      // S-type
                ALUSrc = 1'b1;
                MemWrite = 1'b1;
                ResultSrc = 1'bx;    // Don't care
                branch = 1'b0;
                ALUOp = 2'b00;       // ALU does add
            end
            7'b0110011: begin  // R-type (e.g., ADD, SUB)
                RegWrite = 1'b1;
                ImmSrc = 2'bxx;      // Don't care
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'b0;    // Result from ALU
                branch = 1'b0;
                ALUOp = 2'b10;       // ALU defined by funct
            end
            7'b1100011: begin  // Branch (e.g., BEQ)
                RegWrite = 1'b0;
                ImmSrc = 2'b10;      // B-type
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'bx;    // Don't care
                branch = 1'b1;
                ALUOp = 2'b01;       // ALU does subtract (for BEQ/BNE)
                // NOTE: For BLT/BGE, ALUOp should be 2'b10
                // and ALU_decoder would select SLT/SLTU.
            end
            7'b0010011: begin // I-type (e.g., ADDI)
                RegWrite = 1'b1;
                ImmSrc = 2'b00;      // I-type
                ALUSrc = 1'b1;       // Immediate
                MemWrite = 1'b0;
                ResultSrc = 1'b0;    // Result from ALU
                branch = 1'b0;
                ALUOp = 2'b10;       // ALU defined by funct3
            end
            // --- Add JAL, JALR, LUI, AUIPC for a more complete processor ---
            // 7'b1101111: JAL
            // 7'b1100111: JALR
            // 7'b0110111: LUI
            // 7'b0010111: AUIPC
            
            default: begin
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'b0;
                ALUSrc = 1'b0;
                branch = 1'b0;
                ALUOp = 2'b00;
                ImmSrc = 2'b00;
            end
        endcase

        // PCSrc is active if it's a branch instruction AND the condition is met
        // NOTE: This logic is ONLY for BEQ (funct3=000)
        // For BNE (funct3=001), it would be PCSrc = branch & ~zero;
        // For BLT, it would use the ALU's N flag, etc.
        PCSrc = branch & zero;
    end
endmodule

// --- Program Counter ---
module program_counter(
    input [31:0] PC_NEXT,  // Next value of Program Counter
    input clk,             // Clock
    input rst,             // Reset signal (active low)
    output reg [31:0] PC   // Current value of Program Counter
);

    always @(posedge clk) begin
        if (rst == 1'b0) begin // Active-low reset
            PC <= 32'h00000000;
        end
        else begin
            PC <= PC_NEXT;
        end
    end
endmodule

// --- PC Adder (Generic Adder) ---
module pc_adder(
    input [31:0] a,    // First input
    input [31:0] b,    // Second input
    output [31:0] c    // Output sum
);

assign c = a + b;

endmodule

// --- Register File ---
// FIXED: Added synchronous active-low reset
module register_file(
    input [4:0] A1, A2, A3,   // Read addresses 1, 2; Write address 3
    input [31:0] WD3,         // Write data
    input WE3, clk, rst,      // Write Enable, Clock, Reset (active-low)
    output [31:0] RD1, RD2    // Read Data outputs
);

    // Define 32 registers, each 32 bits wide
    reg [31:0] registers [31:0];

    // Combinational read logic
    // FIXED: Handle x0 (register 0) which must always be 0
    assign RD1 = (A1 == 5'b0) ? 32'h00000000 : registers[A1];
    assign RD2 = (A2 == 5'b0) ? 32'h00000000 : registers[A2];

    integer i; // For reset loop
    
    // Write to register file on positive clock edge
    always @(posedge clk) begin
        if (!rst) begin // Active-low reset
            // On reset, clear all registers
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end
        // FIXED: Do not write to x0 (register 0)
        else if (WE3 && (A3 != 5'b0)) begin
            registers[A3] <= WD3;
        end
    end

endmodule

// --- Sign Extender ---
module sign_extender(
    input [31:0] in,
    input [1:0] ImmSrc,
    output reg [31:0] Imm_ext // <-- FIXED: Changed to 'output reg'
);

    always @(*) begin
        case (ImmSrc)
            // I-type (ADDI, LW, SLTI)
            2'b00: Imm_ext = {{20{in[31]}}, in[31:20]}; 
            // S-type (SW)
            2'b01: Imm_ext = {{20{in[31]}}, in[31:25], in[11:7]};
            // B-type (BEQ)
            2'b10: Imm_ext = {{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1'b0}; // Corrected B-type
            
            // --- Add U-type and J-type immediates here ---
            // 2'b11: U-type? J-type?
            
            default: Imm_ext = {{20{in[31]}}, in[31:20]}; // Default to I-type
        endcase
    end
endmodule

