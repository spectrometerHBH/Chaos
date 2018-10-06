`timescale 1ns/1ps

`include "defines.v"

module branchPredictor(
    input wire clk,
    input wire rst,
    // with Decoder
    input  wire [`branchAddrWidth - 1 : 0] branchAddr,
    output wire prediction,
    // with ROB
    input wire predictorEnable,
    input wire [`branchAddrWidth - 1 : 0] branchAddrUPD,
    input wire taken 
);
    reg  [`historyTableWidth   - 1 : 0] hTable [`predictorSize - 1 : 0];
    reg  [`globalHistoryWidth  - 1 : 0] globalHistory;

    assign prediction = hTable[{globalHistory, branchAddr}][1];

    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `predictorSize; i = i + 1)
                hTable[i] <= `historyTableWidth'b10;
            globalHistory <= 0;
        end else begin
            if (predictorEnable) begin
                globalHistory <= (globalHistory << 1) | taken;
                case (hTable[{globalHistory, branchAddrUPD}])
                    2'b00 : hTable[{globalHistory, branchAddrUPD}] <= (taken ? 2'b01 : 2'b00);
                    2'b01 : hTable[{globalHistory, branchAddrUPD}] <= (taken ? 2'b11 : 2'b00);
                    2'b10 : hTable[{globalHistory, branchAddrUPD}] <= (taken ? 2'b11 : 2'b00);
                    2'b11 : hTable[{globalHistory, branchAddrUPD}] <= (taken ? 2'b11 : 2'b10);
                endcase
            end
        end
    end
endmodule