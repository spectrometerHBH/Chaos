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
    //input from CDB
    input wire aluFinish,
    input wire [`aluRSWidth - 1 : 0] CDB_RSnum,
    input wire [`tagWidth   - 1 : 0] CDB_tag,
    input wire [`dataWidth  - 1 : 0] CDB_data,
    //output to CDB
    output reg aluSignal,
    output reg [`tagWidth   - 1 : 0] CDB_out_tag,
    output reg [`dataWidth  - 1 : 0] CDB_out_data,
    output reg [`aluRSWidth - 1 : 0] CDB_out_RSnum 
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
    always @ (CDB_tag or CDB_data) begin
        for (i = 0; i < `RSsize; i = i + 1) begin
            if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag1Range] == CDB_tag && RS[i][`aluTag1Range] != `tagFree) begin
                RS[i][`aluData1Range] = CDB_data;
                RS[i][`aluTag1Range]  = `tagFree;  
            end
            if (RS[i][`aluOpRange] != `NOP && RS[i][`aluTag2Range] == CDB_tag && RS[i][`aluTag2Range] != `tagFree) begin
                RS[i][`aluData2Range] = CDB_data;
                RS[i][`aluTag2Range]  = `tagFree;
            end
        end
    end

    //Push inst into RS and kick finished inst
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `RSsize; i = i + 1) begin
                RS[i] <= `aluWidth'b0;
            end  
        end else begin
            if (aluFinish) begin
                RS[CDB_RSnum] <= {(`aluWidth){1'b0}};
            end
            if (aluEnable & empty) begin
                for (i = 0; i < `RSsize; i = i + 1) begin
                    if (empty == ((1'b1) << `RSsize) >> (`RSsize - i - 1)) begin
                        RS[i] <= inst;
                    end 
                end
            end
        end
    end

    //Execute
    always @ (*) begin
        aluSignal <= 1'b0;
        for (i = 0; i < `RSsize; i = i + 1) begin
            if (ready == ((1'b1) << `RSsize) >> (`RSsize - i - 1)) begin
                aluSignal <= 1'b1;
                CDB_out_tag <= RS[i][`aluDestRange];
                CDB_out_RSnum <= i;
                case (RS[i][`aluOpRange])
                    `ADD  : CDB_out_data <= $signed(RS[i][`aluData1Range]) +   $signed(RS[i][`aluData2Range]);
                    `SUB  : CDB_out_data <= $signed(RS[i][`aluData1Range]) -   $signed(RS[i][`aluData2Range]);    
                    `SLL  : CDB_out_data <= RS[i][`aluData1Range]          <<  (RS[i][`aluData2Low5Range]);     
                    `SLT  : CDB_out_data <= $signed(RS[i][`aluData1Range]) <   $signed(RS[i][`aluData2Range]) ? 1 : 0;    
                    `SLTU : CDB_out_data <= RS[i][`aluData1Range]          <   RS[i][`aluData2Range]          ? 1 : 0;     
                    `XOR  : CDB_out_data <= $signed(RS[i][`aluData1Range]) ^   $signed(RS[i][`aluData2Range]);  
                    `SRL  : CDB_out_data <= RS[i][`aluData1Range]          >>  (RS[i][`aluData2Low5Range]); 
                    `SRA  : CDB_out_data <= RS[i][`aluData1Range]          >>> (RS[i][`aluData2Low5Range]);
                    `OR   : CDB_out_data <= $signed(RS[i][`aluData1Range]) |   $signed(RS[i][`aluData2Range]); 
                    `AND  : CDB_out_data <= $signed(RS[i][`aluData1Range]) &   $signed(RS[i][`aluData2Range]);
                    default : ;
                endcase
            end
        end
    end
endmodule