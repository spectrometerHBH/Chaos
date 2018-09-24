`timescale 1ns/1ps

`include "defines.v"

module Regfile(
    input clk,
    input rst,
    //Write Port
    input enWirte,
    input [`regWidth  - 1 : 0] namew,
    input [`dataWidth - 1 : 0] dataw,
    input [`]
    //Read Port1
    input enRead1,
    input [`regWidth - 1 : 0] name1,
    output reg [`tagWidth  - 1 : 0] tag1,
    output reg [`dataWidth - 1 : 0] data1,
    //Read Port2
    input enRead2,
    input [`regWidth - 1 : 0] name2,
    output reg [`tagWidth  - 1 : 0] tag2,
    output reg [`dataWidth - 1 : 0] data2
);
    reg [`dataWidth - 1 : 0] data[`regCnt - 1 : 0];
    reg [`tagWidth  - 1 : 0] tag[`regCnt  - 1 : 0];

    integer i;
    always @ (posedge rst) begin
        for (i = 0; i < `regCnt; i = i + 1) begin
            tag[i] <= `tagFree;  
        end
    end

    always @ (*) begin
      if (enRead1) begin
        
      end else begin
        
      end

      if (enRead2) begin
        
      end else begin
        
      end
    end
endmodule 