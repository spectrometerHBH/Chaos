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
    //input from ALUCDB
    input wire ALU_ROB_valid,
    input wire [`tagWidth  - 1 : 0] ALU_CDB_tag,
    input wire [`dataWidth - 1 : 0] ALU_CDB_data,
    //input from branchCDB
    input wire branch_ROB_valid,
    input wire [`tagWidth  - 1 : 0] branch_CDB_tag,
    input wire [`dataWidth - 1 : 0] branch_CDB_data,
    //input from LSBufCDB
    input wire LSBuf_ROB_valid,
    input wire [`tagWidth  - 1 : 0] LSBuf_CDB_tag,
    input wire [`dataWidth - 1 : 0] LSBuf_CDB_data, 
    //output to Fetcher
    output wire freeState,
    //output to Regfile
    output reg regfileEnable,
    output reg [`regWidth  - 1 : 0] rob_reg_name,
    output reg [`dataWidth - 1 : 0] rob_reg_data,
    output reg [`tagWidth  - 1 : 0] rob_reg_tag
);
    //{Ready, Data, Addr, Op}
    reg  [`robWidth - 1 : 0] rob[`ROBsize - 1 : 0];
    reg  [`tagWidth - 1 : 0] frontPointer, tailPointer;
    reg  [`tagWidth - 1 : 0] counter;
    wire [`robWidth - 1 : 0] head;
    wire [`tagWidth - 2 : 0] ALU_CDB_robNumber, branch_CDB_robNumber, LSBuf_CDB_robNumber;
    reg regEnable;

    assign head                 = rob[frontPointer];
    assign headFinish           = (counter != 0 && rob[frontPointer][`robReadyRange]) ? 1 : 0;
    assign freeState            = (counter < `ROBsize) ? 1 : 0;
    assign tailptr              = tailPointer;
    assign ALU_CDB_robNumber    = ALU_CDB_tag   [`tagWidth - 2 : 0];
    assign branch_CDB_robNumber = branch_CDB_tag[`tagWidth - 2 : 0];
    assign LSBuf_CDB_robNumber  = LSBuf_CDB_rag [`tagWidth - 2 : 0];
    
    //Decoder Tag Check
    always @ (*) begin
        case (tagCheck1) 
            `tagFree : begin
                tag1Ready = 1;
                data1 = {(`dataWidth - 1){1'b0}};
            end
            ALU_CDB_tag : begin
                tag1Ready = 1;
                data1 = ALU_CDB_data;
            end
            LSBuf_CDB_tag : begin
                tag1Ready = 1;
                data1 = LSBuf_CDB_data;
            end
            default : begin
                tag1Ready = rob[tagCheck1][`robReadyRange];
                data1 = rob[tagCheck1][`robDataRange];
            end
        endcase
        case (tagCheck2) 
            `tagFree : begin
                tag2Ready = 1;
                data2 = {(`dataWidth - 1){1'b0}};
            end
            ALU_CDB_tag : begin
                tag2Ready = 1;
                data2 = ALU_CDB_data;
            end
            LSBuf_CDB_tag : begin
                tag2Ready = 1;
                data2 = LSBuf_CDB_data;
            end
            default : begin
                tag2Ready = rob[tagCheck2][`robReadyRange];
                data2 = rob[tagCheck2][`robDataRange];
            end
        endcase
    end

    always @ (negedge clk) begin
        if (ALU_CDB_tag) begin
            rob[ALU_CDB_robNumber][`robDataRange] <= ALU_CDB_data;
            rob[ALU_CDB_robNumber][`robReadyRange] <= 1;
        end

        if (branch_ROB_valid) begin
        end

        if (LSBuf_ROB_valid) begin

        end
    end

    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            frontPointer <= 1'b0;
            tailPointer  <= 1'b0;
            counter      <= 1'b0;
            for (i = 0; i < `ROBsize; i = i + 1)
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
        end
    end

    //Execute front
    always @ (*) begin
        regEnable <= 0;
        if (counter && headFinish) begin
            case (head[`robOpRange])
                `robClassNormal: begin
                    regEnable <= 1;
                    rob_reg_name <= head[`robRegRange];
                    rob_reg_data <= head[`robDataRange];
                    rob_reg_tag  <= frontPointer;  
                end
                default : ;
            endcase  
        end
    end
endmodule