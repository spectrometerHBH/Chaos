`timescale 1ns/1ps

`include "defines.v"

module IFetcher(
	//input from PC
	input  wire [`addrWidth - 1 : 0] PC
	//output to ICache
	output reg  [1 : 0] rw_flag,			 //[0] for read, [1] for write, both zero for stall
	output wire [`addrWidth : 0] addr,
	output wire [`dataWidth : 0] write_data, //useless
	output wire [3 : 0] write_mask,		     //useless	
	//input from ICache
	input  wire [`instWidth : 0] read_data,
	input  wire ICache_busy,
	input  wire ICache_done,
	//output to IF/ID
	output reg  [`instWidth - 1 : 0] inst,
	//output to staller
	output reg  stall_req
);
	
	assign addr = PC;

	always @ (*) begin
		if (rst) begin
			rw_flag  = 0;
			addr     = `addrWidth'b0;
		end else begin
			if (ICache_done) begin
				inst      = read_data;
				stall_req = 0;
			end else if (ICache_busy) begin
				rw_flag   = 0;
				stall_req = 1;
			end else if (!ICache_busy) begin
				rw_flag   = 1;
				stall_req = 1;
			end
		end
	end

end module