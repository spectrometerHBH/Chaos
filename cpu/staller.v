`timescale 1ns/1ps

`include "defines.v"

module staller(
	input wire clk,
	input wire rst,
	//IFetcher stall,
	input  wire IFetch_stall,
	output wire PC_stall,
	output wire IFID_stall,
	//branch   stall
	input  wire Decoder_branch_stall,
	input  wire branchALU_complete
);
	assign PC_stall    = IFetch_stall || branch_stalling;
	assign IFID_stall  = IFetch_stall || branch_stalling;
	
	reg branch_stalling;
	always @ (*) begin
		if (rst) branch_stalling = 1'b0;
		else if (branch_stalling == 1'b0 && Decoder_branch_stall) branch_stalling = 1'b1;
		else if (branch_stalling == 1'b1 && branchALU_complete)   branch_stalling = 1'b0; 
	end
endmodule