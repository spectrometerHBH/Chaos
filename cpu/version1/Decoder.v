`timescale 1ns/1ps

`include "defines.vh"

module Decoder(
    //input from PC
    input wire decoderEnable,
    input wire [`instWidth - 1 : 0] instToDecode,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //output to Dispatcher
    output reg dispatch_enable,
    output reg [`classOpWidth - 1 : 0] classop_out,
    output reg [`newopWidth   - 1 : 0] newop_out,
    output reg [`addrWidth    - 1 : 0] inst_PC_out,
    output reg [`reg_sel - 1 : 0] rs1_out,
    output reg [`reg_sel - 1 : 0] rs2_out,
    output reg [`reg_sel - 1 : 0] rd_out,
    output reg [`addrWidth - 1 : 0] Imm_out,
    output reg [`addrWidth  - 1 : 0] UImm_out,
    output reg [`addrWidth  - 1 : 0] JImm_out,
    output reg [`addrWidth  - 1 : 0] BImm_out,
    output reg [`addrWidth  - 1 : 0] SImm_out,
    output reg lock_prefix,
    output reg wr_rd_out
);
    wire [`classOpWidth  - 1 : 0] classop;
    wire [`classOp2Width - 1 : 0] classop2;
    wire [`classOp3Width - 1 : 0] classop3;
    wire [`reg_sel      - 1 : 0]  rd, rs1, rs2;
    reg                           wr_rd;
    reg  [`newopWidth    - 1 : 0] newop;
    

    assign classop  = instToDecode[`classOpRange];
    assign classop2 = instToDecode[`classOp2Range];
    assign classop3 = instToDecode[`classOp3Range];
    assign rd  = instToDecode[`rdRange];
    assign rs1 = instToDecode[`rs1Range];
    assign rs2 = classop == `classRI ? `reg_sel'b0 : instToDecode[`rs2Range];
    
    always @ (*) begin
        newop = `NOP;
        wr_rd = 1;
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
                    wr_rd = 0;
                    case (classop2)
                        3'b000 : begin newop = `SB;  end
                        3'b001 : begin newop = `SH;  end
                        3'b010 : begin newop = `SW;  end
                    endcase             
                end
                `classBranch : begin
                    wr_rd = 0;
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

    wire [`addrWidth - 1 : 0] Imm;
    assign Imm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[`ImmRange]};
    wire [`addrWidth - 1 : 0] UImm;
    assign UImm = {instToDecode[`UImmRange], {(`addrWidth - 20){1'b0}}};
    wire [`addrWidth - 1 : 0] JImm;
    assign JImm = {{(`addrWidth - 20){instToDecode[31]}}, instToDecode[19:12], instToDecode[20], instToDecode[30:21], 1'b0};
    wire [`addrWidth - 1 : 0] BImm;
    assign BImm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[7], instToDecode[30:25], instToDecode[11:8], 1'b0}; 
    wire [`addrWidth - 1 : 0] SImm;
    assign SImm = {{(`addrWidth - 12){instToDecode[31]}}, instToDecode[31:25], instToDecode[11:7]};
    
    always @ (*) begin
        if (decoderEnable) begin
            dispatch_enable = 1;
            classop_out = classop;
            newop_out   = newop;
            inst_PC_out = inst_PC;
            rs1_out = rs1;
            rs2_out = rs2;
            rd_out  = rd;
            Imm_out = Imm;
            UImm_out = UImm;
            JImm_out = JImm;
            BImm_out = BImm;
            SImm_out = SImm;
            lock_prefix = ~(instToDecode[4] | instToDecode[6]);
            wr_rd_out = wr_rd;
        end else begin
            dispatch_enable = 0;
            classop_out = 0;
            newop_out   = `NOP;
            inst_PC_out = 0;
            rs1_out  = 0;
            rs2_out  = 0;
            rd_out   = 0;
            Imm_out  = 0;
            UImm_out = 0;
            JImm_out = 0;
            BImm_out = 0;
            SImm_out = 0;
            lock_prefix = 0;
            wr_rd_out = 0;
        end
    end

endmodule