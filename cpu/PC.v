`timescale 1ns/1ps

`include "defines.v"

module PC(
    input wire clk, 
    input wire rst,
    //input from IFetcher
    input wire PC_stall,
    //output to IFetcher
    output reg  [`addrWidth - 1 : 0] PC,
    //output to IF/ID
    output wire [`addrWidth - 1 : 0] PC_IFID,
    //input from ALU_CDB
    input wire jump_dest_valid,
    input wire [`addrWidth  - 1 : 0] jump_dest,
    //input from branchALU_CDB
    input wire branch_offset_valid,
    input wire [`addrWidth  - 1 : 0] branch_offset
);
    assign PC_IFID = PC;

    always @(negedge clk or posedge rst) begin
    	if (rst) begin
    		PC         <= `addrWidth'b0;
    	end else begin
    		if (PC_stall)                 PC <= PC;
    		else if (jump_dest_valid)     PC <= jump_dest;
            else if (branch_offset_valid) PC <= PC + branch_offset;
            else                          PC <= PC + 4;	
    	end
    end
endmodule