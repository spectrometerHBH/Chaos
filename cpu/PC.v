`timescale 1ns/1ps

`include "defines.v"

module PC(
    (* mark_debug = "true" *) input wire clk, 
    (* mark_debug = "true" *) input wire rst,
    //input from staller
    (* mark_debug = "true" *) input wire PC_stall,
    //output to IFetcher
    (* mark_debug = "true" *) output reg [`addrWidth - 1 : 0] PC
);
    always @(posedge clk or posedge rst) begin
    	if (rst) begin
    		PC <= `addrWidth'b0;
    	end
    	else begin
    		if (PC_stall) PC <= PC;
    		else PC <= PC + 4;	
    	end
    end
endmodule