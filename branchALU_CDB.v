`timescale 1ns/1ps

`include "defines.v"

module branchALU_CDB(
    input clk,
    input rst, 
    //input from branchALU
    input wire branchALUSignal,
    input wire [`branchALURSWidth - 1 : 0] branchALURSNumIn,
    input wire [`tagWidth         - 1 : 0] branchALUTagIn,
    input wire [`dataWidth        - 1 : 0] branchALUDataIn,
    //output to branchALU
    output wire branchALUFinish,
    output wire [`branchALURSWidth - 1 : 0] branchALURSNumOut,
    //output to ROB
    output wire valid_ROB,
    output wire [`tagWidth   - 1 : 0] robTagOut,
    output wire [`dataWidth  - 1 : 0] robDataOut
);

    wire [`tagWidth  - 1 : 0] tagInfo;
    wire [`dataWidth - 1 : 0] dataInfo;

    assign robTagOut       = tagInfo;
    assign robDataOut       = dataInfo;
    assign valid_ROB    = branchALUSignal;
    
    assign valid_branch = branchALUSignal;
    assign branchALURSNumOut = branchALURSNumIn;

    assign tagInfo     = branchALUTagIn;
    assign dataInfo    = branchALUDataIn;

endmodule