`timescale 1ns/1ps

`include "defines.v"

module IF_ID(
	input wire clk,
	input wire rst,
	//input from staller
	input wire stall,
	//input from Fetcher
	input wire [`instWidth - 1 : 0] inst_input,
	//output to Decoder	
	output reg valid, 
	output reg [`instWidth - 1 : 0] inst_output,
	output reg [`addrWidth - 1 : 0] inst_pc,
	//input from PC
	input wire [`addrWidth - 1 : 0] PC
);
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			valid 	    <= 0;
			inst_output <= `instWidth'b0;
			inst_pc          <= 0;
		end else if (stall) begin
			valid 	    <= 0;
			inst_output <= `instWidth'b0;
			inst_pc         <= 0;
		end else begin
			valid 		<= 1;			
			inst_output <= inst_input;
			inst_pc   	<= PC;
		end
	end
endmodule