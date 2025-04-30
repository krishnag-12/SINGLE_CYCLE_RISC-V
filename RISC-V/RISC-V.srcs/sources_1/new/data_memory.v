`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Data Memory
// Module Name: data_memory
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module data_memory(
    input [31:0] A,        // Address input (32-bit)
    input [31:0] WD,       // Write Data input (32-bit)
    input clk,             // Clock signal
    input rst,             // Asynchronous Reset signal (active high)
    input WE,              // Write Enable signal
    output [31:0] RD       // Read Data output (32-bit)
);

    // Declare memory array of 1024 32-bit registers
    reg [31:0] data_mem [1023:0];

    // Declare loop variable OUTSIDE the always block
    integer i;

    // Asynchronous read logic (read is always available when WE is low)
    assign RD = (WE == 1'b0 && !rst) ? data_mem[A] : 32'h00000000;

    // Write and reset logic (asynchronous reset)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, clear the entire memory
            for (i = 0; i < 1024; i = i + 1)
                data_mem[i] <= 32'h00000000;
        end else if (WE) begin
            // On write enable, write data
            data_mem[A] <= WD;
        end
    end

endmodule

module data_memory_tb;

    // Inputs
    reg [31:0] A;     // Address
    reg [31:0] WD;    // Write Data
    reg clk;          // Clock
    reg rst;          // Reset
    reg WE;           // Write Enable

    // Output
    wire [31:0] RD;   // Read Data

    // Instantiate the data_memory module
    data_memory uut (
        .A(A),
        .WD(WD),
        .clk(clk),
        .rst(rst),
        .WE(WE),
        .RD(RD)
    );

    // Clock generation: Toggle every 5 time units
    always #5 clk = ~clk;

    // Initial block for stimulus
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        A = 0;
        WD = 32'h00000000;
        WE = 0;

        // Monitor signals
        $monitor("Time=%0t | clk=%b | rst=%b | WE=%b | Addr=%d | WD=%h | RD=%h", 
                  $time, clk, rst, WE, A, WD, RD);

        // Apply reset
        #2;
        rst = 1;
        #5;
        rst = 0;

        // Write to address 10
        #10;
        A = 32'd10;
        WD = 32'hCAFEBABE;
        WE = 1;

        #10;
        WE = 0;  // Disable write

        // Read from address 10
        #10;
        A = 32'd10;

        // Write to address 100
        #10;
        A = 32'd100;
        WD = 32'hDEADBEEF;
        WE = 1;

        #10;
        WE = 0;

        // Read from address 100
        #10;
        A = 32'd100;

        // Apply reset again - memory should be cleared
        #10;
        rst = 1;
        #5;
        rst = 0;

        // Read from address 10 again - should be zero after reset
        #10;
        A = 32'd10;

        // End simulation
        #10;
        $finish;
    end

endmodule
