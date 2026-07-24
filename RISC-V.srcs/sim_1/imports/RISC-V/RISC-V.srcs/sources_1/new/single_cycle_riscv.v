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
wire [2:0] alu_ctrl_top;     // ALU control signals
wire [1:0] ImmSrc_top;       // Immediate source control
wire Z_top;                  // Zero flag from ALU
wire ALUSrc_top, MemWrite_top, ResultSrc_top, Branch_top, RegWrite_top; // Control signals

// --- NEW Wires for fixed logic ---
wire [31:0] branch_target_addr; // Result of PC + Imm_ext
wire [31:0] pc_next_out;        // Input to PC module (from MUX)
wire [31:0] reg_write_data;     // Input to Register File (from MUX)


// === Program Counter ===
// Note: This module implements an active-low reset
program_counter pc(
    .clk(clk),
    .rst(rst),
    .PC_NEXT(pc_next_out), // <-- FIXED: Connect to MUX output
    .PC(PC_top)          // <-- FIXED: Port order
);

// === PC + 4 Adder ===
pc_adder pcadd(
    .a(PC_top),
    .b(32'd4),
    .c(PCplus4)
);

// --- NEW: Branch Target Adder (PC + immediate) ---
pc_adder branch_addr_adder (
    .a(PC_top),
    .b(Imm_ext_top),
    .c(branch_target_addr)
);

// --- NEW: PC-Next MUX (Selects PC+4 or Branch Target) ---
// Branch_top is the 'PCSrc' signal from main_decoder (branch & zero)
assign pc_next_out = Branch_top ? branch_target_addr : PCplus4;


// === Instruction Memory ===
// Note: Assumes rst is active-low based on logic
instruction_memory inst_mem(
    .rst(rst),
    .A(PC_top),
    .RD(RD_inst)
);

// --- NEW: Register Write-Back MUX ---
// ResultSrc: 0 = ALU Result, 1 = Memory ReadData
assign reg_write_data = ResultSrc_top ? ReadData : alu_result_top;


// === Register File ===
register_file rg_file(
    .clk(clk),
    .rst(rst),
    .A1(RD_inst[19:15]),      // rs1
    .A2(RD_inst[24:20]),      // rs2
    .A3(RD_inst[11:7]),       // rd
    .WD3(reg_write_data),     // <-- FIXED: Connect to MUX output
    .WE3(RegWrite_top),       // Write enable
    .RD1(RD1_top),            // Read data 1
    .RD2(RD2_top)             // Read data 2
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
    .N(), 
    .V(), 
    .C() 
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
// Note: Reset logic is now ACTIVE-LOW
data_memory data_mem(
    .A(alu_result_top),
    .WD(RD2_top),         // Data to be written to memory
    .clk(clk),
    .rst(rst),
    .WE(MemWrite_top),    // Write enable
    .RD(ReadData)         // Read data output
);

endmodule

//================================================================
//                 Component Modules
//================================================================

module alu(
    input [31:0] A, B,     // 32-bit input operands A and B
    input [2:0] alu_ctrl,  // 3-bit ALU control signal
    output reg [31:0] result, // 32-bit output result
    output reg Z, N, V, C     // Flags
    );
    
    reg [32:0] sum;  // 33-bit register for carry/overflow
    
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
            3'b010: begin // MUL (Non-standard for basic RISC-V ALU)
                result = A * B;
                sum = {1'b0, result}; // Simple, no real overflow check
            end
            3'b011: begin // DIV (Non-standard for basic RISC-V ALU)
                result = A / B;
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
            3'b111: begin // XNOR
                result = A ~^ B;
                sum = {1'b0, result};
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
            C = (sum[32] ^ A[31] ^ B[31] ^ result[31]); // More robust carry
        end
        // For SUB:
        if (alu_ctrl == 3'b001) begin
             C = (sum[32] ^ A[31] ^ B[31] ^ result[31]); // More robust borrow
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

module ALU_decoder(
    input [6:0] op,         // 7-bit opcode
    input [6:0] funct7,     // 7-bit funct7 field
    input [2:0] funct3,     // 3-bit funct3 field
    input [1:0] ALUOp,      // ALU operation signal from main decoder
    output reg [2:0] alu_ctrl // Output control signal to ALU
);

    always @(*) begin
        case (ALUOp)
            2'b00: alu_ctrl = 3'b000; // For load/store -> ALU does addition
            2'b01: alu_ctrl = 3'b001; // For branch -> ALU does subtraction
            2'b10: begin              // R-type and I-type
                case ({funct7, funct3})
                    // R-Type
                    10'b0000000_000: alu_ctrl = 3'b000; // ADD
                    10'b0100000_000: alu_ctrl = 3'b001; // SUB
                    10'b0000000_111: alu_ctrl = 3'b100; // AND (was 010)
                    10'b0000000_110: alu_ctrl = 3'b101; // OR (was 011)
                    10'b0000000_100: alu_ctrl = 3'b110; // XOR (was 100)
                    // I-Type (ALUOp is 10, but funct7 doesn't matter)
                    // We can check just funct3 for I-types if op is 0010011
                    default: 
                        if (op == 7'b0010011) begin // I-type immediate
                            case (funct3)
                                3'b000: alu_ctrl = 3'b000; // ADDI
                                3'b111: alu_ctrl = 3'b100; // ANDI
                                3'b110: alu_ctrl = 3'b101; // ORI
                                3'b100: alu_ctrl = 3'b110; // XORI
                                default: alu_ctrl = 3'b000; // Default to ADDI
                            endcase
                        end else begin // R-type default
                            alu_ctrl = 3'b000; // Default to ADD
                        end
                endcase
            end
            default: alu_ctrl = 3'b000; // Safe default
        endcase
    end
endmodule

module control_unit(
    input  [6:0] op,         // 7-bit opcode
    input  [6:0] funct7,     // 7-bit funct7 field
    input  [2:0] funct3,     // 3-bit funct3 field
    input  zero,             // <-- FIXED: Added zero flag input
    output wire RegWrite,    // Register Write enable
    output wire ALUSrc,      // ALU Source select
    output wire MemWrite,    // Memory Write enable
    output wire ResultSrc,   // Selects ALU result or memory read
    output wire Branch,      // Branch signal (renamed from PCSrc)
    output wire [1:0] ImmSrc, // Immediate type selector
    output wire [2:0] alu_ctrl // ALU control signals
);

    // Internal wire to connect ALUOp
    wire [1:0] ALUOp;

    // Instantiate main decoder
    main_decoder m1 (
        .zero(zero),         // <-- FIXED: Connected zero flag
        .op(op),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .PCSrc(Branch),      // <-- FIXED: Port name was PCSrc, not Branch
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );

    // Instantiate ALU decoder
    ALU_decoder a1 (
        .op(op),             // <-- FIXED: Pass full opcode
        .funct7(funct7),     // <-- FIXED: Pass full funct7
        .ALUOp(ALUOp),
        .funct3(funct3),
        .alu_ctrl(alu_ctrl)
    );
endmodule

module data_memory(
    input [31:0] A,        // Address input (Byte Address)
    input [31:0] WD,       // Write Data input
    input clk,             // Clock
    input rst,             // Asynchronous Reset (ACTIVE-LOW)
    input WE,              // Write Enable
    output [31:0] RD       // Read Data output
);

    // Declare memory array of 1024 32-bit registers (4KB)
    reg [31:0] data_mem [1023:0];
    
    // Calculate word address (A[11:2])
    wire [9:0] word_addr = A[11:2];

    // Asynchronous read logic
    // Reads are combinational. Reset behavior is synchronous.
    assign RD = data_mem[word_addr];

    // Write and reset logic (synchronous)
    integer i;
    always @(posedge clk) begin
        if (!rst) begin // <-- FIXED: Changed to active-low reset
            // On reset, clear the entire memory (active-low)
            for (i = 0; i < 1024; i = i + 1)
                data_mem[i] <= 32'h00000000;
        end else if (WE) begin
            // On write enable, write data to word address
            data_mem[word_addr] <= WD;
        end
    end
endmodule

module instruction_memory(
    input [31:0] A,      // Address input (Byte Address)
    input rst,           // Reset signal: active-low
    output [31:0] RD     // Instruction output (Read Data)
    );

    // 1024 x 32-bit memory array (4KB)
    reg [31:0] mem [1023:0];
    
    // Calculate word address (A[11:2])
    wire [9:0] word_addr = A[11:2];

    // Combinational read. Reset is not typically applied to ROM.
    // The PC resetting to 0 handles fetching the first instruction.
    // FIXED: Use active-low reset
    assign RD = (rst == 1'b0) ? 32'h00000000 : mem[word_addr];

endmodule

module main_decoder(
    input zero,            // Zero flag
    input [6:0] op,        // 7-bit opcode
    output reg RegWrite,   // Register write
    output reg MemWrite,   // Memory write
    output reg ResultSrc,  // Result source
    output reg ALUSrc,     // ALU source
    output reg PCSrc,      // PC source for branching
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
                ImmSrc = 2'b00;     // I-type
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                ResultSrc = 1'b1;   // Result from memory
                branch = 1'b0;
                ALUOp = 2'b00;      // ALU does add
            end
            7'b0100011: begin  // Store (e.g., SW)
                RegWrite = 1'b0;
                ImmSrc = 2'b01;     // S-type
                ALUSrc = 1'b1;
                MemWrite = 1'b1;
                ResultSrc = 1'bx;   // Don't care
                branch = 1'b0;
                ALUOp = 2'b00;      // ALU does add
            end
            7'b0110011: begin  // R-type (e.g., ADD, SUB)
                RegWrite = 1'b1;
                ImmSrc = 2'bxx;     // Don't care
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'b0;   // Result from ALU
                branch = 1'b0;
                ALUOp = 2'b10;      // ALU defined by funct
            end
            7'b1100011: begin  // Branch (e.g., BEQ)
                RegWrite = 1'b0;
                ImmSrc = 2'b10;     // B-type
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 1'bx;   // Don't care
                branch = 1'b1;
                ALUOp = 2'b01;      // ALU does subtract
            end
            7'b0010011: begin // I-type (e.g., ADDI)
                RegWrite = 1'b1;
                ImmSrc = 2'b00;     // I-type
                ALUSrc = 1'b1;      // Immediate
                MemWrite = 1'b0;
                ResultSrc = 1'b0;   // Result from ALU
                branch = 1'b0;
                ALUOp = 2'b10;      // ALU defined by funct3
            end
            // Add JAL, JALR, LUI, AUIPC for a more complete processor
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

        // PCSrc is active if it's a branch instruction AND the zero flag is true
        PCSrc = branch & zero;
    end
endmodule

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

module pc_adder(
    input [31:0] a,    // First input
    input [31:0] b,    // Second input
    output [31:0] c    // Output sum
);

assign c = a + b;

endmodule

module register_file(
    input [4:0] A1, A2, A3,   // Read addresses 1, 2; Write address 3
    input [31:0] WD3,         // Write data
    input WE3, clk, rst,      // Write Enable, Clock, Reset
    output [31:0] RD1, RD2    // Read Data outputs
);

    // Define 32 registers, each 32 bits wide
    reg [31:0] registers [31:0];

    // Combinational read logic
    // FIXED: Handle x0 (register 0) which must always be 0
    assign RD1 = (A1 == 5'b0) ? 32'h00000000 : registers[A1];
    assign RD2 = (A2 == 5'b0) ? 32'h00000000 : registers[A2];

    // Write to register file on positive clock edge
    always @(posedge clk) begin
        // FIXED: Do not write to x0 (register 0)
        if (WE3 && (A3 != 5'b0)) begin
            registers[A3] <= WD3;
        end
    end
    
    // Note: This register file does not have a reset for all registers.
    // They will start as 'X' (unknown) until written.
    // This is common, but a full reset could be added.

endmodule

module sign_extender(
    input [31:0] in,
    input [1:0] ImmSrc,
    output reg [31:0] Imm_ext // <-- FIXED: Changed to 'output reg'
);

    always @(*) begin
        case (ImmSrc)
            // I-type (ADDI, LW)
            2'b00: Imm_ext = {{20{in[31]}}, in[31:20]}; 
            // S-type (SW)
            2'b01: Imm_ext = {{20{in[31]}}, in[31:25], in[11:7]};
            // B-type (BEQ)
            2'b10: Imm_ext = {{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1'b0}; // Corrected B-type
            // U-type (LUI) - not specified in main_decoder
            // J-type (JAL) - not specified in main_decoder
            default: Imm_ext = {{20{in[31]}}, in[31:20]}; // Default to I-type
        endcase
    end
endmodule

//module tb_single_cycle_riscv;

//    // Clock and active-low reset
//    reg clk;
//    reg rst_n; // active-low reset

//    // Instantiate DUT
//    single_cycle_riscv uut (
//        .clk(clk),
//        .rst(rst_n)
//    );

//    // Clock generation: 10 ns period (100 MHz)
//    initial begin
//        clk = 0;
//        forever #5 clk = ~clk;
//    end

//    // Stimulus: reset pulse and preload memories / registers
//    initial begin
//        // Start with reset asserted (active-low)
//        rst_n = 1'b0;
//        // Give simulator time to initialize
//        #12;

//        // Preload instruction memory (hierarchical access).
//        // Addresses are word-addressed by PC[11:2].
//        // Instruction encodings (hex):
//        // 0: addi x1, x0, 5   -> 0x00500093
//        // 1: addi x2, x1, 3   -> 0x00308113
//        // 2: add  x3, x1, x2  -> 0x002081B3
//        // 3: sw   x3, 0(x0)   -> 0x00302023
//        // 4: lw   x4, 0(x0)   -> 0x00002203

//        // Note: The instance name of instruction_memory in the DUT is 'inst_mem'
//        // The array inside is 'mem' (reg [31:0] mem [1023:0])
//        // We can assign directly here at time 0.
//        uut.inst_mem.mem[0] = 32'h00500093;
//        uut.inst_mem.mem[1] = 32'h00308113;
//        uut.inst_mem.mem[2] = 32'h002081B3;
//        uut.inst_mem.mem[3] = 32'h00302023;
//        uut.inst_mem.mem[4] = 32'h00002203;

//        // Optionally clear data memory (not required because reset clears it),
//        // but we'll show an example of preloading data memory slot 0 if desired:
//        // uut.data_mem.data_mem[0] = 32'h00000000;

//        // Hold reset for a few clock edges
//        #20;
//        rst_n = 1'b1; // release reset (active-low)

//        // Run for some cycles to execute program
//        #400;

//        // After simulation, display a few contents (registers and data mem)
//        $display("----- Final register file snapshot (x0..x7) -----");
//        $display("x0 = %h", uut.rg_file.registers[0]); // should be 0
//        $display("x1 = %h", uut.rg_file.registers[1]); // expect 5
//        $display("x2 = %h", uut.rg_file.registers[2]); // expect 8
//        $display("x3 = %h", uut.rg_file.registers[3]); // expect 13
//        $display("x4 = %h", uut.rg_file.registers[4]); // expect 13 (loaded)
//        $display("data_mem[0] = %h", uut.data_mem.data_mem[0]); // expect 13

//        $finish;
//    end

//    // Monitor important signals each cycle
//    initial begin
//        // VCD dump for waveform viewing
//        $dumpfile("single_cycle_riscv_tb.vcd");
//        $dumpvars(0, tb_single_cycle_riscv);

//        // Header
//        $display("time\tPC\t\tINST\t\tRD1\t\tRD2\t\tALU_RES\t\tMEM_RD\tRegWrite");
//        $display("--------------------------------------------------------------------------");

//        // Periodic monitor (on positive edge of clk)
//        forever @(posedge clk) begin
//            // Read some hierarchical signals inside the DUT for visibility:
//            // PC: uut.PC_top is internal wire, PC register is uut.pc.PC (program_counter instance named pc)
//            // Fetched instruction is uut.RD_inst or uut.inst_mem.RD (but easier: uut.RD_inst isn't a port; use hierarchical)
//            // We'll use the program_counter instance and inst_mem outputs:
//            $display("%0t\t%h\t%h\t%h\t%h\t%h\t%h\t%b",
//                     $time,
//                     uut.pc.PC,                         // PC register inside program_counter instance
//                     uut.inst_mem.mem[uut.pc.PC[11:2]], // instruction fetched (combinational read)
//                     uut.RD1_top,                       // register file read 1 (wire in top module)
//                     uut.RD2_top,                       // register file read 2
//                     uut.alu_result_top,                // ALU result
//                     uut.ReadData,                      // Data memory read data
//                     uut.RegWrite_top                   // RegWrite control signal
//                     );
//        end
//    end

//endmodule