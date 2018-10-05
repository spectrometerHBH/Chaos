`timescale 1ns/1ps

`include "defines.v"

module branchALU(
	input clk, 
	input rst,
	//output to Fetcher
	output reg [`branchALURSsize - 1 : 0] freeState,
	//input from Decoder
	input wire branchALUEnable, 
	input wire [`branchALUWidth - 1 : 0] inst,  
	//input from aluCDB
	input wire ALU_CDB_valid,
	input wire [`tagWidth   - 1 : 0] ALU_CDB_tag,
	input wire [`dataWidth  - 1 : 0] ALU_CDB_data,
	//input from LSBufCDB
	input wire LSBuf_CDB_valid,
	input wire [`tagWidth   - 1 : 0] LSBuf_CDB_tag,
	input wire [`dataWidth  - 1 : 0] LSBuf_CDB_data,
	//input from branchCDB
	input wire branchALUFinish,
	input wire [`branchALURSWidth   - 1 : 0] branchALU_CDB_RSnum,
	//output to branchALUCDB
	output reg branchALUSignal,
	output reg [`branchALURSWidth   - 1 : 0] branchALU_CDB_out_RSnum, 
	output reg [`tagWidth           - 1 : 0] branchALU_CDB_out_tag,
	output reg [`dataWidth          - 1 : 0] branchALU_CDB_out_data
);
	//{Dest, Tag2, Data2, Tag1, Data1, op}
	reg  [`branchALUWidth - 1 : 0] RS[`branchALURSsize - 1 : 0];
	reg  [`branchALURSsize   - 1 : 0] readyState;
	wire [`branchALURSsize   - 1 : 0] empty;
	wire [`branchALURSsize   - 1 : 0] ready;

	assign empty = freeState & (-freeState);
	assign ready = readyState & (-readyState);

	integer i;
	//Supervise free and ready situation
	always @ (*) begin
		for (i = 0; i < `branchALURSsize; i = i + 1) begin
			freeState[i] = (RS[i][`branchALUOpRange] == `NOP) ? 0 : 1;  
			readyState[i] = (RS[i][`branchALUOpRange] != `NOP && RS[i][`branchALUData1Range] == `tagFree && RS[i][`branchALUData2Range] == `tagFree) ? 1 : 0;
		end      
	end

	//Pull update from CDB
	always @ (negedge clk) begin
		if (rst) begin
			for (i = 0; i < `branchALURSsize; i = i + 1) begin
				RS[i] <= `branchALUWidth'b0;
			end  
		end else begin
			if (ALU_CDB_valid) begin
				for (i = 0; i < `branchALURSsize; i = i + 1) begin
					if (RS[i][`branchALUOpRange] != `NOP && RS[i][`branchALUTag1Range] == ALU_CDB_tag && RS[i][`branchALUTag1Range] != `tagFree) begin
						RS[i][`branchALUData1Range] <= ALU_CDB_data;
						RS[i][`branchALUTag1Range]  <= `tagFree;  
					end
					if (RS[i][`branchALUOpRange] != `NOP && RS[i][`branchALUTag2Range] == ALU_CDB_tag && RS[i][`branchALUTag2Range] != `tagFree) begin
						RS[i][`branchALUData2Range] <= ALU_CDB_data;
						RS[i][`branchALUTag2Range]  <= `tagFree;
					end
				end
			end
			if (branchALUFinish) begin
				RS[branchALU_CDB_RSnum] <= {(`branchALUWidth){1'b0}}; 
			end
			if (LSBuf_CDB_valid) begin
				for (i = 0; i < `branchALURSsize; i = i + 1) begin
					if (RS[i][`branchALUOpRange] != `NOP && RS[i][`branchALUTag1Range] == LSBuf_CDB_tag && RS[i][`branchALUTag1Range] != `tagFree) begin
						RS[i][`branchALUData1Range] <= LSBuf_CDB_data;
						RS[i][`branchALUTag1Range]  <= `tagFree;  
					end
					if (RS[i][`branchALUOpRange] != `NOP && RS[i][`branchALUTag2Range] == LSBuf_CDB_tag && RS[i][`branchALUTag2Range] != `tagFree) begin
						RS[i][`branchALUData2Range] <= LSBuf_CDB_data;
						RS[i][`branchALUTag2Range]  <= `tagFree;
					end
				end
			end
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			branchALUSignal <= `INVALID;
			branchALU_CDB_out_RSnum <= 0;
			branchALU_CDB_out_tag <= `tagFree;
			branchALU_CDB_out_data <= `dataWidth'b0;
			for (i = 0; i < `branchALURSsize; i = i + 1) begin
				RS[i] <= `branchALUWidth'b0;
			end  
		end else begin
			if (branchALUEnable & empty) begin
				for (i = 0; i < `branchALURSsize; i = i + 1) begin
					if (empty == ((1'b1) << `branchALURSsize) >> (`branchALURSsize - i - 1)) begin
						RS[i] <= inst;
					end 
				end
			end
			branchALUSignal <= `INVALID;
			branchALU_CDB_out_RSnum <= 0;
			branchALU_CDB_out_tag <= `tagFree;
			branchALU_CDB_out_data <= `dataWidth'b0;
			for (i = 0; i < `branchALURSsize; i = i + 1) begin
				if (ready == ((1'b1) << `branchALURSsize) >> (`branchALURSsize - i - 1)) begin
					branchALUSignal <= `VALID;
					branchALU_CDB_out_tag <= RS[i][`aluDestRange];
					branchALU_CDB_out_RSnum <= i;
					case (RS[i][`branchALUOpRange])
						`BEQ  : branchALU_CDB_out_data <=
						`BNE  : branchALU_CDB_out_data <= 
						`BLT  : branchALU_CDB_out_data <=
						`BGE  : branchALU_CDB_out_data <=
						`BLTU : branchALU_CDB_out_data <=
						`BGEU : branchALU_CDB_out_data <=
						default : ;
					endcase
				end
			end
		end
	end
endmodule
