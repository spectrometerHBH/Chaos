`timescale 1ns/1ps

`include "defines.v"

module Regfile(
    input wire clk,
    input wire rst,
    //Write Port with ROB
    input wire enWrite,
    input wire [`regWidth  - 1 : 0] namew,
    input wire [`dataWidth - 1 : 0] dataw,
    input wire [`tagWidth  - 1 : 0] tagw,
	//Write Port with Decoder
	input wire enDecoderw,
	input wire [`regWidth - 1 : 0] regDecoderw,
	input wire [`tagWidth - 1 : 0] tagDecoderw,
    //Read Port1
    input wire [`regWidth - 1 : 0] name1,
    output reg [`tagWidth  - 1 : 0] tag1,
    output reg [`dataWidth - 1 : 0] data1,
    //Read Port2
    input wire [`regWidth - 1 : 0] name2,
    output reg [`tagWidth  - 1 : 0] tag2,
    output reg [`dataWidth - 1 : 0] data2,
    //Read Port3
    input wire [`regWidth - 1 : 0] name3,
    output reg [`tagWidth  - 1 : 0] tag3,
    output reg [`dataWidth - 1 : 0] data3
);
    reg [`dataWidth - 1 : 0] data[`regCnt - 1 : 0];
    reg [`tagWidth  - 1 : 0] tag[`regCnt  - 1 : 0];

    integer i;
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			data[0] <= 0;
			for (i = 0; i < `regCnt; i = i + 1) begin
				tag[i] <= `tagFree;  
			end
		end else begin
			if (enWrite) begin
				if (namew) begin
					data[namew] <= dataw;
					if (tag[namew] == tagw) begin
						tag[namew] <= `tagFree;
					end
				end
			end
			if (enDecoderw) begin
				if (regDecoderw) begin
					tag[regDecoderw] <= tagDecoderw;
				end
			end
		end
	end

    always @ (*) begin
		if (rst) begin
			data1 <= 0;
			tag1  <= `tagFree;
		end else if (enWrite && name1 == namew) begin
			data1 = dataw;
			tag1  = tagw;
		end else begin
			data1 = data[name1];
			tag1  = tag [name1];
		end
	end

	always @ (*) begin
		if (rst) begin
			data2 <= 0;
			tag2  <= `tagFree;
		end else if (enWrite && name2 == namew) begin
			data2 = dataw;
			tag2  = tagw;
		end else begin
			data2 = data[name2];
			tag2  = tag [name2];
		end
    end

    always @(*) begin
    	if (rst) begin
    		data3 <= 0;
    		tag3  <= `tagFree;
    	end else if (enWrite && name3 == namew) begin
 			data3 = dataw;
 			tag3  = tagw;   		
    	end else begin
    		data3 = data[name3];
    		tag3  = tag [name3];
    	end
    end
endmodule 