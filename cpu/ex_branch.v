`timescale 1ns / 1ps

`include "defines.vh"

module ex_branch(
    //input form rs_branch
    input wire ex_branch_en,
    input wire [`dataWidth - 1 : 0] exsrc1,
    input wire [`dataWidth - 1 : 0] exsrc2,
    input wire [`addrWidth - 1 : 0] expc,
    input wire [`newopWidth - 1 : 0] exaluop,
    input wire [`dataWidth - 1 : 0] exoffset,
    //output to PC
    output reg branch_dest_valid,
    output reg [`addrWidth - 1 : 0] branch_dest
);
    wire [`addrWidth - 1 : 0] taken, not_taken;
    
    assign taken = expc + exoffset;
    assign not_taken = expc + 4;
    
    always @ (*) begin
        branch_dest_valid = 0;
        branch_dest = 0;
        if (ex_branch_en) begin
            branch_dest_valid = 1;
            case (exaluop)
                `BEQ : begin
                    branch_dest = exsrc1 == exsrc2 ? taken : not_taken;
                end
                `BNE : begin
                    branch_dest = exsrc1 != exsrc2 ? taken : not_taken;
                end
                `BLT : begin
                    branch_dest = $signed(exsrc1) < $signed(exsrc2) ? taken : not_taken;
                end
                `BGE : begin
                    branch_dest = $signed(exsrc1) >= $signed(exsrc2) ? taken : not_taken;
                end
                `BLTU : begin
                    branch_dest = exsrc1 < exsrc2 ? taken : not_taken;
                end
                `BGEU : begin
                    branch_dest = exsrc1 >= exsrc2 ? taken : not_taken;
                end
            endcase
        end
    end
endmodule
