`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Program Counter
// Module Name: program_counter
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module program_counter(
    input [31:0] PC_NEXT,  // Next value of Program Counter
    input clk,             // Clock signal
    input rst,             // Reset signal (active low)
    output reg [31:0] PC   // Current value of Program Counter
);

    // Synchronous logic: triggered on rising edge of clock
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            // If reset is low, reset PC to 0
            PC <= 32'h00000000;
        end
        else begin
            // Else, update PC with next value
            PC <= PC_NEXT;
        end
    end

endmodule

module program_counter_tb;

    // Testbench signals
    reg [31:0] PC_NEXT;    // Input: next PC value
    reg clk;               // Input: clock
    reg rst;               // Input: reset
    wire [31:0] PC;        // Output: current PC

    // Instantiate the program_counter module
    program_counter uut (
        .PC_NEXT(PC_NEXT),
        .clk(clk),
        .rst(rst),
        .PC(PC)
    );

    // Generate clock signal: toggles every 5 time units
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        PC_NEXT = 32'h00000004;

        // Display output changes
        $monitor("Time=%0t | clk=%b | rst=%b | PC_NEXT=%h | PC=%h", 
                  $time, clk, rst, PC_NEXT, PC);

        // Step 1: Apply reset (active low)
        #10;
        rst = 0;  // Hold reset
        #10;
        rst = 1;  // Release reset

        // Step 2: Feed next PC values
        #10;
        PC_NEXT = 32'h00000008;
        #10;
        PC_NEXT = 32'h0000000C;
        #10;
        PC_NEXT = 32'h00000010;

        // Step 3: Reset again mid-way
        #10;
        rst = 0;
        #10;
        rst = 1;

        // Step 4: New PC_NEXT after reset
        PC_NEXT = 32'h00000020;
        #10;

        // End simulation
        $finish;
    end

endmodule
