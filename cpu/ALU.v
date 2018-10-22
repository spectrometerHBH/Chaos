`timescale 1ns/1ps

`include "defines.v"

module ALU(
    input wire clk, 
    input wire rst,
    //output to IFetcher
    output wire free,
    //input from Decoder
    input wire aluEnable, 
    input wire [`aluWidth   - 1 : 0] inst,  
    input wire [`addrWidth  - 1 : 0] inst_pc,
    /*
    //input from LSBufCDB
    input wire LSBuf_CDB_valid,
    input wire [`tagWidth   - 1 : 0] LSBuf_CDB_tag,
    input wire [`dataWidth  - 1 : 0] LSBuf_CDB_data,
    */
    //input from aluCDB
    input wire aluFinish,
    input wire [`aluRSWidth - 1 : 0] ALU_CDB_RSnum,
    input wire [`tagWidth   - 1 : 0] ALU_CDB_tag,
    input wire [`dataWidth  - 1 : 0] ALU_CDB_data,
    //output to aluCDB
    output reg aluSignal,
    output reg [`aluRSWidth - 1 : 0] ALU_CDB_out_RSnum, 
    output reg [`tagWidth   - 1 : 0] ALU_CDB_out_tag,
    output reg [`dataWidth  - 1 : 0] ALU_CDB_out_data,
    output reg [`addrWidth  - 1 : 0] ALU_CDB_out_offset,
    output reg                       ALU_CDB_PC_valid
    //input from ROB
    //input wire mispredictionRst
);
    //{Dest, Tag2, Data2, Tag1, Data1, Op}
    reg  [`aluWidth - 1 : 0] RS[`aluRSsize - 1 : 0];
    reg  [`aluRSsize   - 1 : 0] freeState, readyState;
    wire [`aluRSsize   - 1 : 0] empty;
    wire [`aluRSsize   - 1 : 0] ready;

    assign empty = freeState & (-freeState);
    assign ready = readyState & (-readyState);
    assign free  = empty != 0 ? 1 : 0;

    integer k;
    //Supervise free and ready situation
    always @ (*) begin
        for (k = 0; k < `aluRSsize; k = k + 1) begin
            freeState[k] = (RS[k][`aluOpRange] == `NOP) ? 1 : 0;  
            readyState[k] = (RS[k][`aluOpRange] != `NOP && RS[k][`aluTag1Range] == `tagFree && RS[k][`aluTag2Range] == `tagFree) ? 1 : 0;
        end      
    end

    //Pull update from CDB
    integer j;
    always @ (negedge clk) begin
        if (rst) begin
            for (j = 0; j < `aluRSsize; j = j + 1) begin
                RS[j] <= `aluWidth'b0;
            end  
        end else begin
            if (aluFinish) begin
                aluSignal <= `INVALID;
                RS[ALU_CDB_RSnum] <= {(`aluWidth){1'b0}};
                for (j = 0; j < `aluRSsize; j = j + 1) begin
                    if (RS[j][`aluOpRange] != `NOP && RS[j][`aluTag1Range] == ALU_CDB_tag && RS[j][`aluTag1Range] != `tagFree) begin
                        RS[j][`aluData1Range] <= ALU_CDB_data;
                        RS[j][`aluTag1Range]  <= `tagFree;  
                    end
                    if (RS[j][`aluOpRange] != `NOP && RS[j][`aluTag2Range] == ALU_CDB_tag && RS[j][`aluTag2Range] != `tagFree) begin
                        RS[j][`aluData2Range] <= ALU_CDB_data;
                        RS[j][`aluTag2Range]  <= `tagFree;
                    end
                end
            end
            /*
            if (LSBuf_CDB_valid) begin
                for (i = 0; i < `aluRSsize; i = i + 1) begin
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
            */
        end
    end

    integer i, l;
    always @ (posedge clk) begin
        if (rst) begin
            aluSignal <= `INVALID;
            ALU_CDB_out_RSnum <= 0;
            ALU_CDB_out_tag <= `tagFree;
            ALU_CDB_out_data <= `dataWidth'b0;
            ALU_CDB_out_offset <= 0;
            ALU_CDB_PC_valid <= 0;
            for (l = 0; l < `aluRSsize; l = l + 1) begin
                RS[l] <= `aluWidth'b0;
            end  
        end else begin
            if (aluEnable & empty) begin
                RS[`CLOG2(empty)] <= inst;
            end
            aluSignal <= `INVALID;
            ALU_CDB_out_RSnum <= 0;
            ALU_CDB_out_tag <= `tagFree;
            ALU_CDB_out_data <= `dataWidth'b0;
            ALU_CDB_out_offset <= 0;
            ALU_CDB_PC_valid <= 0;
            if (ready) begin
                i = `CLOG2(ready);
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
                    `LUI  : ALU_CDB_out_data <= RS[i][`aluData2Range];
                    `JAL  : begin 
                        ALU_CDB_out_offset <= $signed(RS[i][`aluData1Range]) + $signed(RS[i][`aluData2Range]);
                        ALU_CDB_out_data   <= $signed(RS[i][`aluData2Range]) + 4;
                        ALU_CDB_PC_valid   <= 1;
                    end
                    `JALR : begin
                        ALU_CDB_out_offset <= ($signed(RS[i][`aluData1Range]) + $signed(RS[i][`aluData2Range])) & 32'hfffffffe;
                        ALU_CDB_out_data   <= inst_pc + 4;
                        ALU_CDB_PC_valid   <= 1;
                    end
                    default : ;
                endcase
            end
        end
    end
endmodule