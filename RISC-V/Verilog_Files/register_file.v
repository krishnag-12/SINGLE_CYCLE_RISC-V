`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Engineer: Krishna Gupta
// 
// Design Name: Register file
// Module Name: register_file
// Project Name: RISC-V Processor
//
//////////////////////////////////////////////////////////////////////////////////

module register_file(
    input [4:0] A1, A2, A3,     // Register addresses: A1 and A2 for reading, A3 for writing
    input [31:0] WD3,           // Write data to be written at A3
    input WE3, clk, rst,        // Write Enable, Clock, and Reset
    output [31:0] RD1, RD2      // Read Data outputs from registers A1 and A2
);

    // Define 32 registers, each 32 bits wide
    reg [31:0] registers [31:0];

    // Continuous assignments for register reads
    assign RD1 = (!rst) ? 32'h00000000 : registers[A1];  // Output 0 when reset is active
    assign RD2 = (!rst) ? 32'h00000000 : registers[A2];

    // Write to register file on positive clock edge
    always @(posedge clk) begin
        if (WE3) begin
            registers[A3] <= WD3;  // Write WD3 to register A3 if Write Enable is high
        end
    end

endmodule

module register_file_tb;

    // Testbench signals
    reg [4:0] A1, A2, A3;
    reg [31:0] WD3;
    reg WE3, clk, rst;
    wire [31:0] RD1, RD2;

    // Instantiate the register_file module
    register_file uut (
        .A1(A1),
        .A2(A2),
        .A3(A3),
        .WD3(WD3),
        .WE3(WE3),
        .clk(clk),
        .rst(rst),
        .RD1(RD1),
        .RD2(RD2)
    );

    // Generate clock signal
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        WE3 = 0;
        A1 = 0; A2 = 0; A3 = 0;
        WD3 = 32'h00000000;

        // Monitor outputs
        $monitor("Time=%0t | rst=%b | clk=%b | A1=%d A2=%d A3=%d | WD3=%h | WE3=%b | RD1=%h RD2=%h",
                 $time, rst, clk, A1, A2, A3, WD3, WE3, RD1, RD2);

        // Apply reset
        #10;
        rst = 1;

        // Write to register 5
        #10;
        A3 = 5; WE3 = 1; WD3 = 32'hABCD1234;

        // Allow write to complete on clock edge
        #10;
        WE3 = 0;

        // Read from register 5 using A1 and A2
        #10;
        A1 = 5; A2 = 5;

        // Write to another register
        #10;
        A3 = 10; WE3 = 1; WD3 = 32'hDEADBEEF;

        #10;
        WE3 = 0;

        // Read from different registers
        #10;
        A1 = 10; A2 = 5;

        // Apply reset again and check output zero
        #10;
        rst = 0;

        // Observe reset effect
        #10;

        // Finish simulation
        $finish;
    end

endmodule
