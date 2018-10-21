`timescale 1ns/1ps

`include "defines.v"

module branchALU_CDB(
    input wire clk,
    input wire rst, 
    //input from branchALU
    input wire                             branchALUSignal,
    input wire [`branchALURSWidth - 1 : 0] branchALURSNumIn,
    input wire                             branchALUResultIn,
    input wire [`addrWidth        - 1 : 0] branchALUOffsetIn,
    //output to branchALU
    output reg                             branchALUFinish,
    output reg [`branchALURSWidth - 1 : 0] branchALURSNumOut,
    //output to PC
    output reg                             branch_offset_valid,
    output reg [`addrWidth        - 1 : 0] branch_offset,
    //output to staller
    output reg                             branch_stall 
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            branchALUFinish     <= 0;
            branchALURSNumOut   <= 0;
            branch_offset_valid <= 0;
            branch_offset       <= 0;
            branch_stall        <= 0;
        end else begin
            branchALUFinish     <= 0;
            branchALURSNumOut   <= 0;
            branch_offset_valid <= 0;
            branch_offset       <= 0;
            branch_stall        <= 0;
            if (branchALUSignal) begin
                branch_stall        <= 1;
                branchALUFinish     <= 1;
                branchALURSNumOut   <= branchALURSNumIn;
                branch_offset_valid <= 1;
                branch_offset       <= branchALUResultIn ? branchALUOffsetIn : 4;
            end
        end
    end

endmodule