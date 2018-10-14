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
    //output to ALU
    output reg aluFinish,
    output reg [`aluRSWidth - 1 : 0] aluRSNumOut,
    output wire [`tagWidth   - 1 : 0] aluTagOut,
    output wire [`dataWidth  - 1 : 0] aluDataOut,
    //output to ROB
    output reg valid_ROB,
    output wire [`tagWidth   - 1 : 0] robTagOut,
    output wire [`dataWidth  - 1 : 0] robDataOut
    /*
    //output to BranchALU
    output wire valid_branch,
    output wire [`tagWidth   - 1 : 0] branchALUTagOut,
    output wire [`dataWidth  - 1 : 0] branchALUDataOut, 
    //output to LSBuffer
    output wire valid_LSBuf,
    output wire [`tagWidth   - 1 : 0] LSBufferTagOut,
    output wire [`dataWidth  - 1 : 0] LSBufferDataOut
    */
);
    reg [`tagWidth  - 1 : 0] tagInfo;
    reg [`dataWidth - 1 : 0] dataInfo;

    assign aluTagOut       = tagInfo;
    assign robTagOut       = tagInfo;
    //assign branchALUTagOut = tagInfo;
    //assign LSBufferTagOut  = tagInfo;

    assign aluDataOut       = dataInfo;
    assign robDataOut       = dataInfo;
    //assign branchALUDataOut = dataInfo;
    //assign LSBufferDataOut  = dataInfo;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aluFinish <= 0;
            valid_ROB <= 0;
            dataInfo  <= `dataWidth'b0;
            tagInfo   <= `tagFree;
        end
        else begin
            aluFinish <= 0;
            valid_ROB <= 0;
            dataInfo  <= `dataWidth'b0;
            tagInfo   <= `tagFree;
            if (aluSignal) begin
                aluFinish   <= 1;
                valid_ROB   <= 1;
                aluRSNumOut <= aluRSNumIn;
                dataInfo    <= aluDataIn;
                tagInfo     <= aluTagIn;
            end
        end
    end
endmodule