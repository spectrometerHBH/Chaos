`timescale 1ns/1ps

`include "defines.v"

module ALU(
    input clk, 
    input rst,

    //input from CDB
    input wire [`ROBTagWidth-1 : 0] CDB_tag,
    input wire [`dataWidth-1 : 0] CDB_data,

    //output to CDB
    output reg [`ROBTagWidth-1 : 0] CDB_out_tag,
    output reg [`dataWidth-1 : 0] CDB_out_data
);
    
endmodule