`timescale 1ns/1ps

`include "defines.v"

module ALU_CDB(
    input wire clk,
    input wire rst, 
    //input from ALU
    input wire aluSignal,
    input wire [`aluRSWidth - 1 : 0] aluRSNumIn,
    input wire [`tagWidth   - 1 : 0] aluTagIn,
    input wire [`dataWidth  - 1 : 0] aluDataIn,
    input wire [`addrWidth  - 1 : 0] aluOffsetIn,
    input wire                       aluPCvalidIn,
    //output to ALU
    output wire aluFinish,
    output wire [`aluRSWidth - 1 : 0] aluRSNumOut,
    output wire [`tagWidth   - 1 : 0] aluTagOut,
    output wire [`dataWidth  - 1 : 0] aluDataOut,
    //output to ROB
    output wire valid_ROB,
    output wire [`tagWidth   - 1 : 0] robTagOut,
    output wire [`dataWidth  - 1 : 0] robDataOut,
    //output to BranchALU
    output wire valid_branch,
    output wire [`tagWidth   - 1 : 0] branchALUTagOut,
    output wire [`dataWidth  - 1 : 0] branchALUDataOut,
    //output to PC
    output wire valid_PC,
    output wire [`addrWidth  - 1 : 0] PCDataOut
    /* 
    //output to LSBuffer
    output wire valid_LSBuf,
    output wire [`tagWidth   - 1 : 0] LSBufferTagOut,
    output wire [`dataWidth  - 1 : 0] LSBufferDataOut
    */
);
    wire [`tagWidth  - 1 : 0] tagInfo;
    wire [`dataWidth - 1 : 0] dataInfo;

    assign aluRSNumOut     = aluRSNumIn;
    assign aluTagOut       = tagInfo;
    assign robTagOut       = tagInfo;
    assign branchALUTagOut = tagInfo;
    //assign LSBufferTagOut  = tagInfo;

    assign aluDataOut       = dataInfo;
    assign robDataOut       = dataInfo;
    assign branchALUDataOut = dataInfo;
    assign PCDataOut        = aluOffsetIn;
    //assign LSBufferDataOut  = dataInfo;

    assign aluFinish        = aluSignal;
    assign valid_ROB        = aluSignal;
    assign valid_branch     = aluSignal;
    assign valid_PC         = aluSignal && aluPCvalidIn;
    //assign jump_complete    = aluSignal && aluPCvalidIn;

    assign dataInfo         = aluSignal ? aluDataIn : 0;
    assign tagInfo          = aluSignal ? aluTagIn  : `tagFree;

endmodule