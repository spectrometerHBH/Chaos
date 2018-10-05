`timescale 1ns/1ps

`include "defines.v"

module ALU(
    input clk, 
    input rst,
    //output to Fetcher
    output reg [`RSsize     - 1 : 0] freeState,
    //input from Decoder
    input wire aluEnable, 
    input wire [`aluWidth   - 1 : 0] inst,  
    //input from LSBufCDB
    input wire LSBuf_CDB_valid,
    input wire [`tagWidth   - 1 : 0] LSBuf_CDB_tag,
    input wire [`dataWidth  - 1 : 0] LSBuf_CDB_data,
    //input from aluCDB
    input wire aluFinish,
    input wire [`aluRSWidth - 1 : 0] ALU_CDB_RSnum,
    input wire [`tagWidth   - 1 : 0] ALU_CDB_tag,
    input wire [`dataWidth  - 1 : 0] ALU_CDB_data,
    //output to aluCDB
    output reg aluSignal,
    output reg [`aluRSWidth - 1 : 0] ALU_CDB_out_RSnum, 
    output reg [`tagWidth   - 1 : 0] ALU_CDB_out_tag,
    output reg [`dataWidth  - 1 : 0] ALU_CDB_out_data
);
    //{Dest, Tag2, Data2, Tag1, Data1, Op}
    reg  [`aluWidth - 1 : 0] RS[`RSsize - 1 : 0];
    reg  [`RSsize   - 1 : 0] readyState;
    wire [`RSsize   - 1 : 0] empty;
    wire [`RSsize   - 1 : 0] ready;

    assign empty = freeState & (-freeState);
    assign ready = readyState & (-readyState);

    integer i;
    //Supervise free and ready situation
    always @ (*) begin
        for (i = 0; i < `RSsize; i = i + 1) begin
            freeState[i] = (RS[i][`aluOpRange] == `NOP) ? 0 : 1;  
            readyState[i] = (RS[i][`aluOpRange] != `NOP && RS[i][`aluData1Range] == `tagFree && RS[i][`aluData2Range] == `tagFree) ? 1 : 0;
        end      
    end

    //Pull update from CDB
    always @ (negedge clk) begin
        if (rst) begin
            for (i = 0; i < `RSsize; i = i + 1) begin
                RS[i] <= `aluWidth'b0;
            end  
        end else begin
            if (aluFinish) begin
                RS[ALU_CDB_RSnum] <= {(`aluWidth){1'b0}};
                for (i = 0; i < `RSsize; i = i + 1) begin
                    if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag1Range] == ALU_CDB_tag && RS[i][`aluTag1Range] != `tagFree) begin
                        RS[i][`aluData1Range] <= ALU_CDB_data;
                        RS[i][`aluTag1Range]  <= `tagFree;  
                    end
                    if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag2Range] == ALU_CDB_tag && RS[i][`aluTag2Range] != `tagFree) begin
                        RS[i][`aluData2Range] <= ALU_CDB_data;
                        RS[i][`aluTag2Range]  <= `tagFree;
                    end
                end
            end
            if (LSBuf_CDB_valid) begin
                for (i = 0; i < `RSsize; i = i + 1) begin
                    if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag1Range] == LSBuf_CDB_tag && RS[i][`aluTag1Range] != `tagFree) begin
                        RS[i][`aluData1Range] <= LSBuf_CDB_data;
                        RS[i][`aluTag1Range]  <= `tagFree;  
                    end
                    if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag2Range] == LSBuf_CDB_tag && RS[i][`aluTag2Range] != `tagFree) begin
                        RS[i][`aluData2Range] <= LSBuf_CDB_data;
                        RS[i][`aluTag2Range]  <= `tagFree;
                    end
                end
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            aluSignal <= `INVALID;
            ALU_CDB_out_RSnum <= 0;
            ALU_CDB_out_tag <= `tagFree;
            ALU_CDB_out_data <= `dataWidth'b0;
            for (i = 0; i < `RSsize; i = i + 1) begin
                RS[i] <= `aluWidth'b0;
            end  
        end else begin
            if (aluEnable & empty) begin
                for (i = 0; i < `RSsize; i = i + 1) begin
                    if (empty == ((1'b1) << `RSsize) >> (`RSsize - i - 1)) begin
                        RS[i] <= inst;
                    end 
                end
            end
            aluSignal <= `INVALID;
            ALU_CDB_out_RSnum <= 0;
            ALU_CDB_out_tag <= `tagFree;
            ALU_CDB_out_data <= `dataWidth'b0;
            for (i = 0; i < `RSsize; i = i + 1) begin
                if (ready == ((1'b1) << `RSsize) >> (`RSsize - i - 1)) begin
                    aluSignal <= `VALID;
                    ALU_CDB_out_tag <= RS[i][`aluDestRange];
                    ALU_CDB_out_RSnum <= i;
                    case (RS[i][`aluOpRange])
                        `ADD  : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) +   $signed(RS[i][`aluData2Range]);
                        `SUB  : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) -   $signed(RS[i][`aluData2Range]);    
                        `SLL  : ALU_CDB_out_data <= RS[i][`aluData1Range]          <<  (RS[i][`aluData2Low5Range]);     
                        `SLT  : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) <   $signed(RS[i][`aluData2Range]) ? 1 : 0;    
                        `SLTU : ALU_CDB_out_data <= RS[i][`aluData1Range]          <   RS[i][`aluData2Range]          ? 1 : 0;     
                        `XOR  : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) ^   $signed(RS[i][`aluData2Range]);  
                        `SRL  : ALU_CDB_out_data <= RS[i][`aluData1Range]          >>  (RS[i][`aluData2Low5Range]); 
                        `SRA  : ALU_CDB_out_data <= RS[i][`aluData1Range]          >>> (RS[i][`aluData2Low5Range]);
                        `OR   : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) |   $signed(RS[i][`aluData2Range]); 
                        `AND  : ALU_CDB_out_data <= $signed(RS[i][`aluData1Range]) &   $signed(RS[i][`aluData2Range]);
                        default : ;
                    endcase
                end
            end
        end
    end
endmodule