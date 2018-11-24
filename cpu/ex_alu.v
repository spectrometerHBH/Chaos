`timescale 1ns / 1ps

`include "defines.vh"

module ex_alu(
    //input from rs_alu
    input wire ex_alu_en,
    input wire [`dataWidth - 1 : 0] exsrc1,
    input wire [`dataWidth - 1 : 0] exsrc2,
    input wire [`addrWidth - 1 : 0] expc,
    input wire [`newopWidth - 1 : 0] exaluop,
    input wire [`tagWidth - 1 : 0] exdest,
    //output to FU & rob
    output reg en_rst,
    output reg [`dataWidth - 1 : 0] rst_data,
    output reg [`tagWidth  - 1 : 0] rst_tag,
    //output to PC
    output reg jump_dest_valid,
    output reg [`addrWidth - 1 : 0] jump_dest
);
    
    always @ (*) begin
        en_rst = 0;
        rst_data = 0;
        rst_tag = `tagFree;
        jump_dest_valid = 0;
        jump_dest = 0;
        if (ex_alu_en) begin
            en_rst = 1;      
            rst_tag = exdest;
            case (exaluop) 
                `ADD  : rst_data = $signed(exsrc1) +   $signed(exsrc2);
                `SUB  : rst_data = $signed(exsrc1) -   $signed(exsrc2);
                `SLL  : rst_data = exsrc1          <<  exsrc2[4 : 0];
                `SLT  : rst_data = $signed(exsrc1) <   $signed(exsrc2) ? 1 : 0;
                `SLTU : rst_data = exsrc1          <   exsrc2          ? 1 : 0;
                `XOR  : rst_data = $signed(exsrc1) ^   $signed(exsrc2);
                `SRL  : rst_data = exsrc1          >>  exsrc2[4 : 0];
                `SRA  : rst_data = exsrc1          >>> exsrc2[4 : 0];
                `OR   : rst_data = $signed(exsrc1) |   $signed(exsrc2);
                `AND  : rst_data = $signed(exsrc1) &   $signed(exsrc2);
                `LUI  : rst_data = exsrc2;
                `JAL  : begin
                    jump_dest = $signed(exsrc1) + $signed(exsrc2);
                    rst_data  = $signed(exsrc2) + 4;
                    jump_dest_valid = 1;
                end
                `JALR : begin
                    jump_dest = $signed(exsrc1) + $signed(exsrc2);
                    rst_data  = expc + 4;
                    jump_dest_valid = 1; 
                end
                `AUIPC : rst_data  = $signed(exsrc1) + $signed(exsrc2);
                default : begin
                end
            endcase    
        end
    end
endmodule
