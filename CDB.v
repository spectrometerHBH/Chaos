`timescale 1ns/1ps

`include "defines.v"

module CDB(
    //input from ALU
    input wire aluSignal,
    input wire [`aluRSWidth - 1 : 0] aluRSNumIn,
    input wire [`tagWidth   - 1 : 0] aluTagIn,
    input wire [`dataWidth  - 1 : 0] aluDataIn,
    //output to ALU
    output reg aluFinish,
    output wire [`aluRSWidth - 1 : 0] aluRSNumOut,
    output wire [`tagWidth   - 1 : 0] aluTagOut,
    output wire [`dataWidth  - 1 : 0] aluDataOut,
    //output to ROB
    output wire [`tagWidth   - 1 : 0] robTagOut,
    output wire [`dataWidth  - 1 : 0] tobDataOut
);
    reg [`tagWidth  - 1 : 0] tagInfo;
    reg [`dataWidth - 1 : 0] dataInfo;

    assign aluTagOut = tagInfo;
    assign aluDataOut = dataInfo;
    assign aluRSNumOut = aluRSNumIn;
    assign robTagOut = tagInfo;
    assign robDataOut = dataInfo;
    
    always @ (*) begin
        aluFinish = 0;
        if (aluSignal) begin
            aluFinish = 1;
            tagInfo = aluTagIn;
            dataInfo = aluDataIn;
        end else begin
            aluFinish = 0;  
        end
    end
    
endmodule