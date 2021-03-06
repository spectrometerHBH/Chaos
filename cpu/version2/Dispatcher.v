`timescale 1ns / 1ps

`include "defines.vh"

module Dispatcher(
     //input from Decoder1
     input wire dispatch_enable1,
     input wire [`classOpWidth - 1 : 0] classop1,
     input wire [`newopWidth   - 1 : 0] newop1,
     input wire [`addrWidth    - 1 : 0] inst_PC1,
     input wire [`reg_sel - 1 : 0] rs1_1,
     input wire [`reg_sel - 1 : 0] rs2_1,
     input wire [`reg_sel - 1 : 0] rd_1,
     input wire [`addrWidth - 1 : 0] Imm_1,
     input wire [`addrWidth  - 1 : 0] UImm_1,
     input wire [`addrWidth  - 1 : 0] JImm_1,
     input wire [`addrWidth  - 1 : 0] BImm_1,
     input wire [`addrWidth  - 1 : 0] SImm_1,
     input wire lock_prefix_1,
     input wire wr_rd_1,
     input wire isbranch_1,
     input wire predict_1,
     //output from Decoder2
     input wire dispatch_enable2,
     input wire [`classOpWidth - 1 : 0] classop2,
     input wire [`newopWidth   - 1 : 0] newop2,
     input wire [`addrWidth    - 1 : 0] inst_PC2,
     input wire [`reg_sel - 1 : 0] rs1_2,
     input wire [`reg_sel - 1 : 0] rs2_2,
     input wire [`reg_sel - 1 : 0] rd_2,
     input wire [`addrWidth - 1 : 0] Imm_2,
     input wire [`addrWidth  - 1 : 0] UImm_2,
     input wire [`addrWidth  - 1 : 0] JImm_2,
     input wire [`addrWidth  - 1 : 0] BImm_2,
     input wire [`addrWidth  - 1 : 0] SImm_2,
     input wire lock_prefix_2,
     input wire wr_rd_2,
     input wire isbranch_2,
     input wire predict_2,
     //input from Regfile
     input wire [`tagWidth - 1 : 0] tag1_1_reg,
     input wire [`tagWidth - 1 : 0] tag2_1_reg,
     input wire [`dataWidth - 1 : 0] data1_1_reg,
     input wire [`dataWidth - 1 : 0] data2_1_reg,
     input wire [`tagWidth - 1 : 0] tag1_2_reg,
     input wire [`tagWidth - 1 : 0] tag2_2_reg,
     input wire [`dataWidth - 1 : 0] data1_2_reg,
     input wire [`dataWidth - 1 : 0] data2_2_reg,
     //output to Regfile
     output wire [`reg_sel - 1 : 0] regAddr1_1,
     output wire [`reg_sel - 1 : 0] regAddr2_1,
     output wire [`reg_sel - 1 : 0] regAddr1_2,
     output wire [`reg_sel - 1 : 0] regAddr2_2,
     //output to ROB
     output wire [`tagWidth - 1 : 0] tag1_1_out,
     output wire [`tagWidth - 1 : 0] tag2_1_out,
     output wire [`tagWidth - 1 : 0] tag1_2_out,
     output wire [`tagWidth - 1 : 0] tag2_2_out,
     output reg rob_enable1,
     output wire isbranch1,
     output reg wr_rd1,
     output reg [`reg_sel   - 1 : 0] rob_dest1,
     output reg [`indexWidth - 1 : 0] rob_PC1,
     output reg rob_enable2,
     output wire isbranch2,
     output reg wr_rd2,
     output reg [`reg_sel - 1 : 0] rob_dest2,
     output reg [`indexWidth - 1 : 0] rob_PC2,
     //input from ROB
     input wire ready1_1,
     input wire [`dataWidth - 1 : 0] data1_1_rob,
     input wire ready2_1,
     input wire [`dataWidth - 1 : 0] data2_1_rob,
     input wire ready1_2,
     input wire [`dataWidth - 1 : 0] data1_2_rob,
     input wire ready2_2,
     input wire [`dataWidth - 1 : 0] data2_2_rob,
     //output to ALU
     output reg  alu_enable_1,
     output reg  [`newopWidth - 1 : 0] alu_op_1,
     output reg  [`dataWidth  - 1 : 0] alu_data1_1,
     output reg  [`tagWidth   - 1 : 0] alu_tag1_1,
     output reg  [`dataWidth  - 1 : 0] alu_data2_1,
     output reg  [`tagWidth   - 1 : 0] alu_tag2_1,
     output wire [`addrWidth  - 1 : 0] alu_PC_1,
     output reg  [`tagWidth   - 1 : 0] alu_dest_1,
     output reg  alu_enable_2,
     output reg  [`newopWidth - 1 : 0] alu_op_2,
     output reg  [`dataWidth  - 1 : 0] alu_data1_2,
     output reg  [`tagWidth   - 1 : 0] alu_tag1_2,
     output reg  [`dataWidth  - 1 : 0] alu_data2_2,
     output reg  [`tagWidth   - 1 : 0] alu_tag2_2,
     output wire [`addrWidth  - 1 : 0] alu_PC_2,
     output reg  [`tagWidth   - 1 : 0] alu_dest_2,
     //output to branch
     output reg  branch_enable,
     output reg  [`newopWidth - 1 : 0] branch_op,
     output reg  [`dataWidth  - 1 : 0] branch_data1,
     output reg  [`tagWidth   - 1 : 0] branch_tag1,
     output reg  [`dataWidth  - 1 : 0] branch_data2,
     output reg  [`tagWidth   - 1 : 0] branch_tag2,
     output reg  [`addrWidth  - 1 : 0] branch_offset,
     output reg  [`addrWidth  - 1 : 0] branch_PC,
     output reg  [`tagWidth   - 1 : 0] branch_dest,
     //output to ls
     output reg ls_enable1,
     output reg [`newopWidth - 1 : 0] ls_op_1,
     output reg [`dataWidth  - 1 : 0] ls_base_1,
     output reg [`tagWidth   - 1 : 0] ls_basetag_1,
     output reg [`dataWidth  - 1 : 0] ls_src_1,
     output reg [`tagWidth   - 1 : 0] ls_srctag_1,
     output reg [`addrWidth  - 1 : 0] ls_Imm_1,
     output reg [`tagWidth   - 1 : 0] ls_dest_1,
     output reg ls_enable2,
     output reg [`newopWidth - 1 : 0] ls_op_2,
     output reg [`dataWidth  - 1 : 0] ls_base_2,
     output reg [`tagWidth   - 1 : 0] ls_basetag_2,
     output reg [`dataWidth  - 1 : 0] ls_src_2,
     output reg [`tagWidth   - 1 : 0] ls_srctag_2,
     output reg [`addrWidth  - 1 : 0] ls_Imm_2,
     output reg [`tagWidth   - 1 : 0] ls_dest_2,
     //output to regFile
     output reg reg_enable1,
     output reg [`reg_sel - 1 : 0] reg_sel1,
     output reg [`tagWidth - 1 : 0] reg_tag1,
     output reg reg_enable2,
     output reg [`reg_sel - 1 : 0] reg_sel2,
     output reg [`tagWidth - 1 : 0] reg_tag2,
     //lock status
     input wire [`tagWidth - 1 : 0] lock1,
     input wire [`tagWidth - 1 : 0] lock2
);
    wire [`dataWidth - 1 : 0] data1_1, data2_1, data1_2, data2_2;
    wire [`tagWidth - 1 : 0] tag1_1, tag2_1, tag1_2, tag2_2;
    wire [`tagWidth - 1 : 0] tag_n_1, tag_n_2;
    
    assign isbranch1 = isbranch_1;
    assign isbranch2 = isbranch_2;
    
    assign regAddr1_1 = rs1_1;
    assign regAddr2_1 = rs2_1;
    assign regAddr1_2 = rs1_2;
    assign regAddr2_2 = rs2_2;
    
    assign tag1_1_out = tag1_1_reg;
    assign tag2_1_out = tag2_1_reg;
    assign tag1_2_out = tag1_2_reg;
    assign tag2_2_out = tag2_2_reg;
    
    assign alu_PC_1 = inst_PC1;
    assign alu_PC_2 = inst_PC2;
    
    assign tag1_1  = (tag1_1_reg == `tagFree || ready1_1) ? `tagFree : tag1_1_reg;
    assign data1_1 = (tag1_1_reg == `tagFree) ? data1_1_reg : data1_1_rob;
    assign tag2_1  = (tag2_1_reg == `tagFree || ready2_1) ? `tagFree : tag2_1_reg;
    assign data2_1 = (tag2_1_reg == `tagFree) ? data2_1_reg : data2_1_rob;
    assign tag1_2  = (tag1_2_reg == `tagFree || ready1_2) ? `tagFree : tag1_2_reg;
    assign data1_2 = (tag1_2_reg == `tagFree) ? data1_2_reg : data1_2_rob;
    assign tag2_2  = (tag2_2_reg == `tagFree || ready2_2) ? `tagFree : tag2_2_reg;
    assign data2_2 = (tag2_2_reg == `tagFree) ? data2_2_reg : data2_2_rob;
    
    assign tag_n_1 = (wr_rd_1 && rd_1 == rs1_2) ? lock1 : tag1_2;
    assign tag_n_2 = (wr_rd_1 && rd_1 == rs2_2) ? lock1 : tag2_2;
    
    always @ (*) begin
        alu_enable_1 = 0;
        alu_op_1 = 0;
        alu_data1_1 = 0;
        alu_tag1_1 = `tagFree;
        alu_data2_1 = 0;
        alu_tag2_1 = `tagFree;
        alu_dest_1 = `tagFree;
        alu_enable_2 = 0;
        alu_op_2 = 0;
        alu_data1_2 = 0;
        alu_tag1_2 = `tagFree;
        alu_data2_2 = 0;
        alu_tag2_2 = `tagFree;
        alu_dest_2 = `tagFree;
        branch_enable = 0;
        branch_op = 0;
        branch_data1 = 0;
        branch_tag1 = `tagFree;
        branch_data2 = 0;
        branch_tag2 = `tagFree;
        branch_offset = 0;
        branch_PC = 0;
        ls_enable1 = 0;
        ls_op_1 = 0;
        ls_base_1 = 0;
        ls_basetag_1 = `tagFree;
        ls_src_1 = 0;
        ls_srctag_1 = `tagFree;
        ls_Imm_1 = 0;
        ls_dest_1 = `tagFree;
        ls_enable2 = 0;
        ls_op_2 = 0;
        ls_base_2 = 0;
        ls_basetag_2 = `tagFree;
        ls_src_2 = 0;
        ls_srctag_2 = `tagFree;
        ls_Imm_2 = 0;
        ls_dest_2 = `tagFree;
        reg_enable1 = 0;
        reg_sel1 = 0;
        reg_tag1 = `tagFree;
        reg_enable2 = 0;
        reg_sel2 = 0;
        reg_tag2 = `tagFree;
        rob_enable1 = 0;
        rob_PC1 = 0;
        rob_dest1 = 0;
        rob_enable2 = 0;
        rob_dest2 = 0;
        rob_PC2 = 0;
        wr_rd1 = 0;
        wr_rd2 = 0;
        if (dispatch_enable1) begin
            rob_enable1 = 1;
            rob_dest1 = rd_1;
            rob_PC1 = inst_PC1[`indexWidth + 1 : 2];
            wr_rd1 = wr_rd_1;
            case (classop1)
                `classRI : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = data1_1;
                    alu_tag1_1  = tag1_1;
                    alu_data2_1 = Imm_1;
                    alu_tag2_1  = `tagFree;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;
                end
                `classRR : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = data1_1;
                    alu_tag1_1  = tag1_1;
                    alu_data2_1 = data2_1;
                    alu_tag2_1  = tag2_1;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;
                end
                `classLUI : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = data1_1;
                    alu_tag1_1  = `tagFree;
                    alu_data2_1 = UImm_1;
                    alu_tag2_1  = `tagFree;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;           
                end
                `classAUIPC : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = inst_PC1;
                    alu_tag1_1  = `tagFree;
                    alu_data2_1 = UImm_1;
                    alu_tag2_1  = `tagFree;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;
                end
                `classJAL : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = JImm_1;
                    alu_tag1_1  = `tagFree;
                    alu_data2_1 = inst_PC1;
                    alu_tag2_1  = `tagFree;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;                                     
                end
                `classJALR : begin
                    alu_enable_1 = 1;
                    alu_data1_1 = data1_1;
                    alu_tag1_1  = tag1_1;
                    alu_data2_1 = Imm_1;
                    alu_tag2_1  = `tagFree;
                    alu_op_1 = newop1;
                    alu_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;                                   
                end
                `classBranch : begin
                    branch_enable = 1;
                    branch_op = newop1;
                    branch_data1 = data1_1;
                    branch_tag1 = tag1_1;
                    branch_data2 = data2_1;
                    branch_tag2 = tag2_1;
                    branch_offset = BImm_1;
                    branch_PC = inst_PC1;
                    branch_dest = lock1;
                    wr_rd1 = predict_1;
                end
                `classLoad : begin
                    ls_enable1 = 1;
                    ls_op_1 = newop1;
                    ls_base_1 = data1_1;
                    ls_basetag_1 = tag1_1;
                    ls_src_1  = data2_1;
                    ls_srctag_1 = tag2_1;
                    ls_Imm_1 = Imm_1;
                    ls_dest_1 = lock1;
                    reg_enable1 = 1;
                    reg_sel1 = rd_1;
                    reg_tag1 = lock1;                    
                end
                `classSave : begin
                    ls_enable1 = 1;
                    ls_op_1 = newop1;
                    ls_base_1 = data1_1;
                    ls_basetag_1 = tag1_1;
                    ls_src_1  = data2_1;
                    ls_srctag_1 = tag2_1;
                    ls_Imm_1 = SImm_1;
                    ls_dest_1 = lock1;
                end
            endcase
            
            if (dispatch_enable2) begin
                rob_enable2 = 1; 
                rob_dest2 = rd_2;
                rob_PC2 = inst_PC2[`indexWidth + 1 : 2];
                wr_rd2 = wr_rd_2;
                case (classop2)
                    `classRI : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = data1_2;
                        alu_tag1_2  = tag_n_1;
                        alu_data2_2 = Imm_2;
                        alu_tag2_2  = `tagFree;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;
                    end
                    `classRR : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = data1_2;
                        alu_tag1_2  = tag_n_1;
                        alu_data2_2 = data2_2;
                        alu_tag2_2  = tag_n_2;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;
                    end
                    `classLUI : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = data1_2;
                        alu_tag1_2  = `tagFree;
                        alu_data2_2 = UImm_2;
                        alu_tag2_2  = `tagFree;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;                    
                    end
                    `classAUIPC : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = inst_PC2;
                        alu_tag1_2  = `tagFree;
                        alu_data2_2 = UImm_2;
                        alu_tag2_2  = `tagFree;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;
                    end
                    `classJAL : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = JImm_2;
                        alu_tag1_2  = `tagFree;
                        alu_data2_2 = inst_PC2;
                        alu_tag2_2  = `tagFree;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;                                     
                    end
                    `classJALR : begin
                        alu_enable_2 = 1;
                        alu_data1_2 = data1_2;
                        alu_tag1_2  = tag_n_1;
                        alu_data2_2 = Imm_2;
                        alu_tag2_2  = `tagFree;
                        alu_op_2 = newop2;
                        alu_dest_2 = lock2;
                        reg_enable2 = 1;
                        reg_sel2 = rd_2;
                        reg_tag2 = lock2;                                   
                    end
                    `classBranch : begin
                        branch_enable = 1;
                        branch_op = newop2;
                        branch_data1 = data1_2;
                        branch_tag1 = tag_n_1;
                        branch_data2 = data2_2;
                        branch_tag2 = tag_n_2;
                        branch_offset = BImm_2;
                        branch_PC = inst_PC2;
                        branch_dest = lock2;
                        wr_rd2 = predict_2;
                    end
                    `classLoad : begin
                        if (lock_prefix_1 == lock_prefix_2) begin
                            ls_enable2 = 1;
                            ls_op_2 = newop2;
                            ls_base_2 = data1_2;
                            ls_basetag_2 = tag_n_1;
                            ls_src_2  = data2_2;
                            ls_srctag_2 = tag_n_2;
                            ls_Imm_2 = Imm_2;
                            ls_dest_2 = lock2;
                            reg_enable2 = 1;
                            reg_sel2 = rd_2;
                            reg_tag2 = lock2;                    
                        end else begin
                            ls_enable1 = 1;
                            ls_op_1 = newop2;
                            ls_base_1 = data1_2;
                            ls_basetag_1 = tag_n_1;
                            ls_src_1  = data2_2;
                            ls_srctag_1 = tag_n_2;
                            ls_Imm_1 = Imm_2;
                            ls_dest_1 = lock2;
                            reg_enable2 = 1;
                            reg_sel2 = rd_2;
                            reg_tag2 = lock2;
                        end
                    end
                    `classSave : begin
                        if (lock_prefix_1 == lock_prefix_2) begin
                            ls_enable2 = 1;
                            ls_op_2 = newop2;
                            ls_base_2 = data1_2;
                            ls_basetag_2 = tag_n_1;
                            ls_src_2  = data2_2;
                            ls_srctag_2 = tag_n_2;
                            ls_Imm_2 = SImm_2;
                            ls_dest_2 = lock2;
                        end else begin
                            ls_enable1 = 1;
                            ls_op_1 = newop2;
                            ls_base_1 = data1_2;
                            ls_basetag_1 = tag_n_1;
                            ls_src_1  = data2_2;
                            ls_srctag_1 = tag_n_2;
                            ls_Imm_1 = SImm_2;
                            ls_dest_1 = lock2;
                        end
                    end
                endcase            
            end
        end 
    end
endmodule