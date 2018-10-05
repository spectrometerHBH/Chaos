`timescale 1ns/1ps

`include "defines.v"

module ROB(
    input clk,
    input rst,
    //input from Decoder
    input wire robInsertEnable,
    input wire [`robWidth - 1 : 0] instToInsert,
    input wire [`tagWidth - 1 : 0] tagCheck1,
    input wire [`tagWidth - 1 : 0] tagCheck2,
    //output to Decoder
    output wire tailptr,
    output reg tag1Ready,
    output reg tag2Ready,
    output reg [`dataWidth - 1 : 0] data1,
    output reg [`dataWidth - 1 : 0] data2,
    //input from CDB
    input wire [`tagWidth  - 1 : 0] CDB_tag,
    input wire [`dataWidth - 1 : 0] CDB_data,
    //output to Fetcher
    output wire freeState
);
    //{Ready, Data, Addr, Op}
    reg [`robWidth - 1 : 0] rob[`ROBsize - 1 : 0];
    reg [`tagWidth - 1 : 0] frontPointer, tailPointer;
    reg [`tagWidth - 1 : 0] counter;
    wire [`robWidth       - 1 : 0] head;

    assign head = rob[frontPointer];
    assign headFinish = (counter != 0 && rob[frontPointer][`robReadyRange]) ? 1 : 0;
    assign freeState = (counter < `ROBsize) ? 1 : 0;
    assign tailptr = tailPointer;
    
    //Decoder Tag Check
    always @ (*) begin
        if (tagCheck1 == `tagFree) begin
            tag1Ready = 1;
            data1 = {(`dataWidth - 1){1'b0}};
        end else if (tagCheck1 == CDB_tag) begin
            tag1Ready = 1;
            data1 = CDB_data;
        end else begin
            tag1Ready = rob[tagCheck1][`robReadyRange];
            data1 = rob[tagCheck1][`robDataRange];
        end
        if (tagCheck2 == `tagFree) begin
            tag2Ready = 1;
            data2 = {(`dataWidth - 1){1'b0}};
        end else if (tagCheck2 == CDB_tag) begin
            tag2Ready = 1;
            data2 = CDB_data;
        end else begin
            tag2Ready = rob[tagCheck2][`robReadyRange];
            data2 = rob[tagCheck2][`robDataRange];
        end
    end

    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            frontPointer <= 1'b0;
            tailPointer  <= 1'b0;
            counter      <= 1'b0;
            for (i = 0; i < `ROBsize - 1; i = i + 1)
                rob[i] <= `ROBsize'b0;
        end else begin
            //Kick front
            if (headFinish) begin
                counter <= counter - 1;
                rob[frontPointer] <= {(`robWidth){1'b0}};
                frontPointer <= frontPointer + 1;
            end
            //Insert inst
            if (freeState) begin
                if (robInsertEnable) begin
                    counter <= counter + 1;
                    rob[tailPointer] <= instToInsert;
                    tailPointer <= tailPointer + 1; 
                end
            end
            //Pull update from CDB
            
        end
    end

endmodule