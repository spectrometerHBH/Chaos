`timescale 1ns/1ps

`include "defines.v"

module IF_ID(
	input wire clk,
	input wire rst,
	//input from PC
	input wire enable,
	input wire [`addrWidth - 1 : 0] PC,
	input wire [`instWidth - 1 : 0] inst_input,
	//output to Decoder
	output reg valid,
	output reg [`instWidth - 1 : 0] inst_output,
	output reg [`addrWidth - 1 : 0] inst_pc
);
    //reg valid;
    //reg [`instWidth - 1 : 0] inst_output;
    //reg [`addrWidth - 1 : 0] inst_pc;
    
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			valid 	    	<= 0;
			inst_output 	<= `instWidth'b0;
			inst_pc         <= 0;
		end else begin
			if (!enable) begin
				valid 	    	<= 0;
				inst_output 	<= `instWidth'b0;
				inst_pc         <= 0;
			end else begin
				valid 			<= 1;			
				inst_output 	<= inst_input;
				inst_pc   		<= PC;
			end
		end
	end
endmodule