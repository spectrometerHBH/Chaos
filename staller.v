`timescale 1ns/1ps

`include "defines.v"

module staller(
	//IFetcher stall,
	input  wire IFetch_stall,
	output wire PC_stall,
	output wire IFIDS_stall
);
	//stall when instrunction fectching
	assign PC_stall    = IFetch_stall;
	assign IFIDS_stall = IFetch_stall;
	
endmodule