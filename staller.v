`timescale 1ns/1ps

`include "defines.v"

module staller(
	//IFetcher stall,
	input  wire IFetch_stall,
	output wire PC_stall,
	output wire IFID_stall
);
	//stall when instrunction fectching
	assign PC_stall    = IFetch_stall;
	assign IFID_stall = IFetch_stall;

endmodule