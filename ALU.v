`timescale 1ns/1ps

`include "defines.v"

module ALU(
    input clk, 
    input rst,
    //output to Fetcher
    output reg [`RSsize    - 1 : 0] freeState,
    //input from Decoder
    input wire [`aluWidth  - 1 : 0] inst,  
    //input from CDB
    input wire [`tagWidth  - 1 : 0] CDB_tag,
    input wire [`dataWidth - 1 : 0] CDB_data,
    //output to CDB
    output reg [`tagWidth  - 1 : 0] CDB_out_tag,
    output reg [`dataWidth - 1 : 0] CDB_out_data
);
    reg  [`aluWidth - 1 : 0] RS[`RSsize - 1 : 0];
    wire [`RSsize   - 1 : 0] empty;
    
    assign empty = freeState & (-freeState);

    //Pull update from CDB
    integer i;
    always @ (CDB_tag or CDB_data) begin
        for (i = 0; i < `RSsize; i = i + 1) begin
            if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag1Range] == CDB_tag && RS[i][`aluTag1Range] != `tagFree) begin
                RS[i][`aluData1Range] = CDB_data;
                RS[i][`aluTag1Range]  = CDB_tag;  
            end
            if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag2Range] == CDB_tag && RS[i][`aluTag2Range] != `tagFree) begin
                RS[i][`aluData2Range] = CDB_data;
                RS[i][`aluTag2Range]  = CDB_tag;
            end
        end
    end

    //Put inst into RS
    integer j;
    always @ (inst) begin
        for (j = 0; j < `RSsize; j = j + 1) begin
            if (empty == ((1'b1) << `RSsize) >> (`RSsize - j - 1)) begin
                RS[j] = inst;
            end 
        end
    end

    //Execute
    
endmodule