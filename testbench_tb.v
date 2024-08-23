`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2024 22:05:42
// Design Name: 
// Module Name: testbench_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_tb();
reg clk,reset;
wire eop;
initial 
clk=1'b0;
always #5 clk=~clk;

initial 
begin
reset=1'b0;
#2reset=1'b1;
end

risc dut(clk,reset,eop);


endmodule
