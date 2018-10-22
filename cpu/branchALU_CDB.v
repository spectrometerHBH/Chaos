`timescale 1ns/1ps

`include "defines.v"

module branchALU_CDB(
    input wire clk,
    input wire rst, 
    //input from branchALU
    input wire                             branchALUSignal,
    input wire [`branchALURSWidth - 1 : 0] branchALURSNumIn,
    input wire                             branchALUResultIn,
    input wire [`addrWidth        - 1 : 0] branchALUOffsetIn,
    //output to branchALU
    output wire                             branchALUFinish,
    output wire [`branchALURSWidth - 1 : 0] branchALURSNumOut,
    //output to PC
    output wire                             branch_offset_valid,
    output wire [`addrWidth        - 1 : 0] branch_offset,
    //output to IFetcher
    output wire                             branch_complete 
);

    assign branchALUFinish     = branchALUSignal;
    assign branchALURSNumOut   = branchALUSignal ? branchALURSNumIn : 0;
    assign branch_offset_valid = branchALUSignal;  
    assign branch_offset       = branchALUSignal ? (branchALUResultIn ? branchALUOffsetIn : 4) : 0;
    assign branch_complete     = branchALUSignal;

endmodule