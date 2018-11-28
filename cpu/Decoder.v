`timescale 1ns/1ps

`include "defines.vh"

module Decoder(
    //input from PC
    input wire decoderEnable,
    input wire [`instWidth - 1 : 0] instToDecode,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //output to ALU
    output reg  aluEnable,
    output reg  [`aluWidth - 1 : 0] aluData,
    output wire [`addrWidth - 1 : 0] inst_PC_out_alu,
    //output to branch
    output reg branchEnable,
    output reg [`branchWidth - 1 : 0] branchData,
    output wire [`addrWidth - 1 : 0] inst_PC_out_branch,
    //output to ls
    output reg lsEnable,
    output reg [`lsWidth - 1 : 0 ] lsData,
    //input from ROB
    input wire tag1Ready,
    input wire tag2Ready,
    input wire tagdReady,
    input wire [`tagWidth  - 2 : 0] ROBtail,
    input wire [`dataWidth - 1 : 0] robData1,
    input wire [`dataWidth - 1 : 0] robData2,
    input wire [`dataWidth - 1 : 0] robDatad,
    //output to ROB
    output reg robEnable,
    output reg [`regWidth - 1 : 0] robData,
    output wire [`tagWidth - 1 : 0] tagCheck1,
    output wire [`tagWidth - 1 : 0] tagCheck2,
    output wire [`tagWidth - 1 : 0] tagCheckd,
    //input from Regfile
    input wire [`tagWidth - 1 : 0] regTag1,
    input wire [`tagWidth - 1 : 0] regTag2,
    input wire [`tagWidth - 1 : 0] regTagd,
    input wire [`dataWidth - 1 : 0] regData1,
    input wire [`dataWidth - 1 : 0] regData2,
    input wire [`dataWidth - 1 : 0] regDatad,
    //output to Regfile
    output wire [`regWidth - 1 : 0] regAddr1,
    output wire [`regWidth - 1 : 0] regAddr2,
    output wire [`regWidth - 1 : 0] regAddrd,
    output reg regEnable,
    output reg [`regWidth - 1 : 0] regTagAddr,
    output reg [`tagWidth - 1 : 0] regTag
);
    wire [`classOpWidth  - 1 : 0] classop;
    wire [`classOp2Width - 1 : 0] classop2;
    wire [`classOp3Width - 1 : 0] classop3;
    wire [`RIImmWidth    - 1 : 0] Imm;
    wire [`regWidth      - 1 : 0] rd, rs1, rs2;
    wire [`dataWidth     - 1 : 0] data1, data2, datad;
    wire [`tagWidth      - 1 : 0] tag1,  tag2,  tagd;
    reg  [`newopWidth    - 1 : 0] newop;
    reg  [3                  : 0] robClass;
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
    assign regAddrd = rd;
    assign tagCheck1 = regTag1;
    assign tagCheck2 = regTag2;
    assign tagCheckd = regTagd;
    assign tag1  = (regTag1 == `tagFree || tag1Ready) ? `tagFree : regTag1;
    assign data1 = (regTag1 == `tagFree) ? regData1 : robData1;
    assign tag2  = (regTag2 == `tagFree || tag2Ready) ? `tagFree : regTag2;
    assign data2 = (regTag2 == `tagFree) ? regData2 : robData2;
    assign tagd  = (regTagd == `tagFree || tagdReady) ? `tagFree : regTagd;
    assign datad = (regTagd == `tagFree) ? regDatad : robDatad;
    assign inst_PC_out_alu = inst_PC;
    assign inst_PC_out_branch = inst_PC;
    
    always @ (*) begin
        newop = `NOP;
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
                        3'b000 : begin newop = `LB; end
                        3'b001 : begin newop = `LH;  end
                        3'b010 : begin newop = `LW; end
                        3'b100 : begin newop = `LBU; end
                        3'b101 : begin newop = `LHU; end
                    endcase             
                end
                `classSave : begin
                    case (classop2)
                        3'b000 : begin newop = `SB;  end
                        3'b001 : begin newop = `SH;  end
                        3'b010 : begin newop = `SW;  end
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
                    newop    = `LUI;
                end
                `classAUIPC : begin
                    newop    = `AUIPC;
                end
                `classJAL : begin
                    newop    = `JAL;
                end
                `classJALR : begin
                    newop    = `JALR;
                end
            endcase
        end
    end

    // LUI
    wire [`UImmWidth - 1 : 0] UImm;
    assign UImm = instToDecode[`UImmRange];

    // JAL
    wire [`addrWidth - 1 : 0] JImm;
    assign JImm = {{(`addrWidth - 20){instToDecode[31]}}, instToDecode[19:12], instToDecode[20], instToDecode[30:21], 1'b0};

    //branch
    wire [`addrWidth - 1 : 0] BImm;
    assign BImm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[7], instToDecode[30:25], instToDecode[11:8], 1'b0}; 
    
    //save
    wire [`addrWidth - 1 : 0] SImm;
    assign SImm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[31:25], instToDecode[11:7]};
    
    //generate request to rs, rob & reg
    always @ (*) begin
        aluEnable       = 0;
        robEnable       = 0;
        lsEnable        = 0;
        regEnable       = 0;
        branchEnable    = 0;
        aluData         = 0;
        robData         = 0;
        branchData      = 0;
        lsData          = 0;
        regTagAddr      = 0;
        regTag          = `tagFree;
        if (decoderEnable) begin
            case (classop)
                `classRI : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, `tagFree, {{(`dataWidth - `RIImmWidth){Imm[`RIImmWidth - 1]}}, Imm}, tag1, data1, newop
                    };    
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classRR : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, tag2, data2, tag1, data1, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classLUI : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, `tagFree, {UImm, {(`dataWidth - `UImmWidth){1'b0}}}, tagd, datad, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classAUIPC : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, `tagFree, {UImm, {(`dataWidth - `UImmWidth){1'b0}}}, `tagFree, inst_PC, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classJAL : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, `tagFree, inst_PC, `tagFree, JImm, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classJALR : begin
                    aluEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    aluData = {
                        ROBtail, `tagFree, {{(`dataWidth - `RIImmWidth){Imm[`RIImmWidth - 1]}}, Imm}, tag1, data1, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classBranch : begin
                    branchEnable = 1;
                    branchData = {
                        BImm, tag2, data2, tag1, data1, newop
                    };
                end
                `classLoad : begin
                    lsEnable = 1;
                    robEnable = 1;
                    regEnable = 1;
                    lsData = {
                        ROBtail, {{(`dataWidth - `RIImmWidth){Imm[`RIImmWidth - 1]}}, Imm}, tag2, data2, tag1, data1, newop
                    };
                    robData = rd;
                    regTagAddr = rd;
                    regTag = {1'b0, ROBtail};
                end
                `classSave : begin
                    lsEnable = 1;
                    regEnable = 1;
                    lsData = {
                        3'b0, SImm, tag2, data2, tag1, data1, newop     
                    };
                end
                default : ;
           endcase
        end
    end

endmodule