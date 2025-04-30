`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Krishna Gupta
// 
// Design Name: Instruction Memory
// Module Name: instruction_memory
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory(
    input [31:0] A,     // Address input
    input rst,          // Reset signal: active high
    output [31:0] RD    // Instruction output (Read Data)
    );

    // 1024 x 32-bit memory array
    reg [31:0] mem [1023:0];

    // Output instruction at address A[31:2] when rst is high
    assign RD = (rst == 1'b0) ? 32'h00000000 : mem[A[31:2]];

endmodule


module instruction_memory_tb;

    // Inputs
    reg [31:0] A;
    reg rst;

    // Output
    wire [31:0] RD;

    // Instantiate the Unit Under Test (UUT)
    instruction_memory uut (
        .A(A), 
        .rst(rst), 
        .RD(RD)
    );

    // Initialize the memory with sample instructions (manually for test)
    initial begin
        // Set initial values
        rst = 0;
        A = 0;

        // Directly writing to memory through simulation scope
        uut.mem[0] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        uut.mem[1] = 32'h00100093; // ADDI x1, x0, 1
        uut.mem[2] = 32'h00200113; // ADDI x2, x0, 2

        #10;
        $display("With rst = 0, RD = %h", RD); // Should print 00000000

        rst = 1; #10;
        A = 32'd0;  #10; $display("A = 0, RD = %h", RD); // Should print 00000013
        A = 32'd4;  #10; $display("A = 4, RD = %h", RD); // Should print 00100093
        A = 32'd8;  #10; $display("A = 8, RD = %h", RD); // Should print 00200113

        rst = 0; #10;
        A = 32'd4;  #10; $display("With rst = 0 again, RD = %h", RD); // Should print 00000000

        $finish;
    end
      
endmodule
