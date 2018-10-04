`timescale 1ns/1ps

`include "defines.v"

module Decoder(
    input wire clk,
    input wire rst,

    //input from IF
    input wire [`instWidth-1 : 0] instToDecode,
    //output to ALU
    output reg enALU,
    output wire [`aluWidth - 1 : 0] aluData,
    //input from ROB
    input wire tag1Ready,
    input wire tag2Ready,
    input wire [`dataWidth - 1 : 0] robData1,
    input wire [`dataWidth - 1 : 0] robData2,
    //output to ROB
    output wire [`tagWidth - 1 : 0] tagCheck1,
    output wire [`tagWidth - 1 : 0] tagCheck2,
    //input from Regfile
    input wire [`tagWidth - 1 : 0] regTag1,
    input wire [`tagWidth - 1 : 0] regTag2,
    input wire [`dataWidth - 1 : 0] regData1,
    input wire [`dataWidth - 1 : 0] regData2,
    //output to Regfile
    output wire [`regWidth - 1 : 0] regAddr1,
    output wire [`regWidth - 1 : 0] regAddr2
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
    always @ (*) begin
        if (instToDecode == `nopinstr) begin
                newop = `NOP;
        end else if (classop == `classRI) begin
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
        end else if (classop == `classRR) begin
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
        end else if (classop == `classLoad) begin
            case (classop2)
                3'b000 : newop = `LB;
                3'b001 : newop = `LH;
                3'b010 : newop = `LW;
                3'b100 : newop = `LBU;
                3'b101 : newop = `LHU;
            endcase
        end else if (classop == `classSave) begin
            case (classop2)
                3'b000 : newop = `SB;
                3'b001 : newop = `SH;
                3'b010 : newop = `SW;
            endcase
        end else if (classop == `classBranch) begin
            case (classop2)
                3'b000 : newop = `BEQ;
                3'b001 : newop = `BNE;
                3'b100 : newop = `BLT;
                3'b101 : newop = `BGE;
                3'b110 : newop = `BLTU;
                3'b111 : newop = `BGEU;
            endcase
        end else if (classop == `classLUI) begin
            newop = `LUI;
        end else if (classop == `classAUIPC) begin
            newop = `AUIPC;
        end else if (classop == `classJAL) begin
            newop = `JAL;
        end else if (classop == `classJALR) begin
            newop = `JALR;
        end
    end

    //Write TO FU
    always @ (*) begin

    end
endmodule