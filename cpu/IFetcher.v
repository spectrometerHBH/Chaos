`timescale 1ns/1ps

`include "defines.v"

module IFetcher(
	input  wire clk,
	input  wire rst,
	//input from PC
	input  wire [`addrWidth - 1 : 0] PC,
	//output to ICache
	output wire [1 : 0] rw_flag,			 //[0] for read, [1] for write, both zero for stall
	output wire [`addrWidth - 1 : 0] addr,
	output wire [`dataWidth - 1: 0] write_data, //useless
	output wire [3 : 0] write_mask,		     //useless	
	//input from ICache
	input  wire [`instWidth - 1: 0] read_data,
	input  wire ICache_busy,
	input  wire ICache_done,
	//output to IF/ID
	output reg   IFID_stall,
	output wire  [`instWidth - 1 : 0] inst,
	//output to PC
	output wire PC_stall,
	//input from ALURS
	input  wire alu_free,
	//input from ROB
	input  wire rob_free,
	//input from ALU_CDB
	input  wire jump_complete,
	//input from branchALU_CDB
	input  wire branch_complete
);
	reg branch_stalling;
	wire staller;
	reg first_inst;

	assign addr = PC;
	assign inst 	   = read_data;
	assign staller     = rst || branch_stalling || !alu_free || !rob_free || ICache_busy || first_inst ? 1 : 0;
	assign rw_flag     = staller && !first_inst ? 0 : 1;
	assign PC_stall    = staller;

	always @(*) begin
		if (rst) begin
			branch_stalling = 0;
			first_inst = 1;
			IFID_stall = 1;
		end else begin
			if (ICache_done) begin
				//done = 1
				if (first_inst) first_inst = 0;
				case (read_data[`classOpRange])
					`classBranch : branch_stalling = 1; 
					`classAUIPC  : branch_stalling = 1;
					`classJAL    : branch_stalling = 1;
					`classJALR   : branch_stalling = 1;
					default : branch_stalling = 0;
				endcase
				IFID_stall = 0;
			end else if (ICache_busy) begin
				//busy = 1 done = 0
				IFID_stall = 1;
			end else if (!ICache_busy) begin
				//busy = 0 done = 0
				IFID_stall = 1;
			end
		end
	end

	always @(*) begin
		if (jump_complete || branch_complete) begin
			branch_stalling = 0;
		end
	end
	
endmodule