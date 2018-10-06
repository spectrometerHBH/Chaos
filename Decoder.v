`timescale 1ns/1ps

`include "defines.v"

module Decoder(
    input wire clk,
    input wire rst,
    //input from IF
    input wire decoderEnable,
    input wire [`instWidth-1 : 0] instToDecode,
    //output to ALU
    output reg aluEnable,
    output reg [`aluWidth - 1 : 0] aluData,
    //output to branchALU
    output reg branchALUEnable,
    output reg [`branchALUWidth - 1 : 0] branchALUData,
    //input from ROB
    input wire tag1Ready,
    input wire tag2Ready,
    input wire ROBtail,
    input wire [`dataWidth - 1 : 0] robData1,
    input wire [`dataWidth - 1 : 0] robData2,
    //output to ROB
    output reg robEnable,
    output reg [`robWidth - 1 : 0] robData,
    output wire [`tagWidth - 1 : 0] tagCheck1,
    output wire [`tagWidth - 1 : 0] tagCheck2,
    //input from Regfile
    input wire [`tagWidth - 1 : 0] regTag1,
    input wire [`tagWidth - 1 : 0] regTag2,
    input wire [`dataWidth - 1 : 0] regData1,
    input wire [`dataWidth - 1 : 0] regData2,
    //output to Regfile
    output wire [`regWidth - 1 : 0] regAddr1,
    output wire [`regWidth - 1 : 0] regAddr2,
    output reg regEnable,
    output reg [`regWidth - 1 : 0] regTagAddr,
    output reg [`tagWidth - 1 : 0] regTag
);
    wire [`classOpWidth  - 1 : 0] classop;
    wire [`classOp2Width - 1 : 0] classop2;
    wire [`classOp3Width - 1 : 0] classop3;
    wire [`RIImmWidth    - 1 : 0] Imm;
    wire [`regWidth      - 1 : 0] rd, rs1, rs2;
    wire [`dataWidth     - 1 : 0] data1, data2;
    wire [`tagWidth      - 1 : 0] tag1,  tag2;
    reg  [`newopWidth    - 1 : 0] newop;

    //Decode the instruction
    //ALU
    assign classop  = instToDecode[`classOpRange];
    assign classop2 = instToDecode[`classOp2Range];
    assign classop3 = instToDecode[`classOp3Range];
    assign rd  = instToDecode[`rdRange];
    assign rs1 = instToDecode[`rs1Range];
    assign rs2 = classop == `classRI ? `regWidth'b0 : instToDecode[`rs2Range];
    assign Imm = instToDecode[`ImmRange];
    assign regAddr1 = rs1;
    assign regAddr2 = rs2;
    assign tagCheck1 = regTag1;
    assign tagCheck2 = regTag2;
    assign tag1  = (regTag1 == `tagFree || tag1Ready) ? `tagFree : regTag1;
    assign data1 = (regTag1 == `tagFree) ? regData1 : robData1;
    assign tag2  = (regTag2 == `tagFree || tag2Ready) ? `tagFree : regTag2;
    assign data2 = (regTag2 == `tagFree) ? regData2 : robData2; 
    //branchALU
    assign branchImm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[7], instToDecode[30:25], instToDecode[8], 1'b0};
    
    always @ (*) begin
        if (instToDecode == `nopinstr) begin
            newop = `NOP;
        end else begin
            case (classop)
                `classRI : begin
                    case (classop2) 
                        3'b000 : newop = `ADD;
                        3'b010 : newop = `SLT;
                        3'b011 : newop = `SLTU;
                        3'b100 : newop = `XOR;
                        3'b110 : newop = `OR;
                        3'b111 : newop = `AND;
                        3'b001 : newop = `SLL;
                        3'b101 : newop = classop3 == 7'b0000000 ? `SRL : `SRA;
                    endcase                 
                end
                `classRR : begin
                    case (classop2) 
                        3'b000 : newop = classop3 == 7'b0000000 ? `ADD : `SUB;
                        3'b001 : newop = `SLL;
                        3'b010 : newop = `SLT;
                        3'b011 : newop = `SLTU;
                        3'b100 : newop = `XOR;
                        3'b101 : newop = classop3 == 7'b0000000 ? `SRL : `SRA;
                        3'b110 : newop = `OR;
                        3'b111 : newop = `AND;
                    endcase                  
                end
                `classLoad : begin
                    case (classop2)
                        3'b000 : newop = `LB;
                        3'b001 : newop = `LH;
                        3'b010 : newop = `LW;
                        3'b100 : newop = `LBU;
                        3'b101 : newop = `LHU;
                    endcase                  
                end
                `classSave : begin
                    case (classop2)
                        3'b000 : newop = `SB;
                        3'b001 : newop = `SH;
                        3'b010 : newop = `SW;
                    endcase                  
                end
                `classBranch : begin
                    case (classop2)
                        3'b000 : newop = `BEQ;
                        3'b001 : newop = `BNE;
                        3'b100 : newop = `BLT;
                        3'b101 : newop = `BGE;
                        3'b110 : newop = `BLTU;
                        3'b111 : newop = `BGEU;
                    endcase                  
                end
                `classLUI : begin
                    newop = `LUI;
                end
                `classAUIPC : begin
                    newop = `AUIPC;
                end
                `classJAL : begin
                    newop = `JAL;
                end
                `classJALR : begin
                    newop = `JALR;
                end
            endcase
        end
    end

    //Write TO FU, ROB and Regfile
    always @ (negedge clk) begin
        aluEnable <= 0;
        robEnable <= 0;
        regEnable <= 0;
        case (classop)
            `classRI : begin
                aluEnable <= 1;
                robEnable <= 1;
                regEnable <= 1;
                aluData <= {
                    ROBtail, `tagFree, Imm, tag1, data1, newop
                };    
                robData <= {
                    1'b0, {`dataWidth{1'b0}}, {{(`addrWidth-`regWidth){1'b0}}, rd}, `robClassNormal    
                };
                regTagAddr <= rd;
                regTag <= ROBtail;
            end
            `classRR : begin
                aluEnable <= 1;
                robEnable <= 1;
                regEnable <= 1;
                aluData <= {
                    ROBtail, tag2, data2, tag1, data1, newop
                };
                robData <= {
                    1'b0, {`dataWidth{1'b0}}, {{(`addrWidth-`regWidth){1'b0}}, rd}, `robClassNormal    
                };
                regTagAddr <= rd;
                regTag <= ROBtail;
            end
            `classLoad : begin

            end
            `classSave : begin
              
            end
            `classBranch : begin
              
            end
            `classLUI : begin

            end
            `classAUIPC : begin
              
            end
            `classJAL : begin
              
            end
            `classJALR : begin
            
            end
            default : ;
    end
endmodule