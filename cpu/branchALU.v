`timescale 1ns/1ps

`include "defines.v"

module branchALU(
	input wire clk, 
	input wire rst,
	input wire exclk,
	//input from Decoder
	input wire branchALUEnable, 
	input wire [`branchALUWidth - 1 : 0] inst,  
	//input from aluCDB
	input wire ALU_CDB_valid,
	input wire [`tagWidth   - 1 : 0] ALU_CDB_tag,
	input wire [`dataWidth  - 1 : 0] ALU_CDB_data,
	/*
	//input from LSBufCDB
	input wire LSBuf_CDB_valid,
	input wire [`tagWidth   - 1 : 0] LSBuf_CDB_tag,
	input wire [`dataWidth  - 1 : 0] LSBuf_CDB_data,*/
	//input from branchCDB
	input wire branchALUFinish,
	input wire [`branchALURSWidth   - 1 : 0] branchALU_CDB_RSnum,
	//output to branchALUCDB
	output reg 								 branchALUSignal,
	output reg [`branchALURSWidth   - 1 : 0] branchALU_CDB_out_RSnum, 
	output reg 						         branchALU_CDB_out_result,
	output reg [`addrWidth          - 1 : 0] branchALU_CDB_out_offset
);
	//{Off, Tag2, Data2, Tag1, Data1, op}
	reg  [`branchALUWidth - 1 : 0] RS[`branchALURSsize - 1 : 0];
	reg  [`branchALURSsize   - 1 : 0] freeState, readyState;
	wire [`branchALURSsize   - 1 : 0] empty;
	wire [`branchALURSsize   - 1 : 0] ready;

	assign empty = freeState & (-freeState);
	assign ready = readyState & (-readyState);

	integer k;
	//Supervise free and ready situation
	always @ (*) begin
		for (k = 0; k < `branchALURSsize; k = k + 1) begin
			freeState[k] = (RS[k][`branchALUOpRange] == `NOP) ? 1 : 0;  
			readyState[k] = (RS[k][`branchALUOpRange] != `NOP && RS[k][`branchALUTag1Range] == `tagFree && RS[k][`branchALUTag2Range] == `tagFree) ? 1 : 0;
		end      
	end

	//Pull update from CDB
	/*
	integer j;
	always @ (negedge clk) begin
		if (rst) begin
			for (j = 0; j < `branchALURSsize; j = j + 1) begin
				RS[j] <= `branchALUWidth'b0;
			end  
		end else begin
			if (ALU_CDB_valid) begin
				for (j = 0; j < `branchALURSsize; j = j + 1) begin
					if (RS[j][`branchALUOpRange] != `NOP && RS[j][`branchALUTag1Range] == ALU_CDB_tag && RS[j][`branchALUTag1Range] != `tagFree) begin
						RS[j][`branchALUData1Range] <= ALU_CDB_data;
						RS[j][`branchALUTag1Range]  <= `tagFree;  
					end
					if (RS[j][`branchALUOpRange] != `NOP && RS[j][`branchALUTag2Range] == ALU_CDB_tag && RS[j][`branchALUTag2Range] != `tagFree) begin
						RS[j][`branchALUData2Range] <= ALU_CDB_data;
						RS[j][`branchALUTag2Range]  <= `tagFree;
					end
				end
			end
			if (branchALUFinish) begin
				RS[branchALU_CDB_RSnum] <= {(`branchALUWidth){1'b0}}; 
			end
			/*
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
	*/

	integer i, l;
	always @ (posedge exclk or posedge rst) begin
		if (rst) begin
			branchALUSignal 	       <= `INVALID;
			branchALU_CDB_out_RSnum    <= 0;
			branchALU_CDB_out_result   <= 0; 
			branchALU_CDB_out_offset   <= `addrWidth'b0;
			for (l = 0; l < `branchALURSsize; l = l + 1) begin
				RS[l] <= `branchALUWidth'b0;
			end  
		end else begin
			if (clk) begin
				if (branchALUEnable & empty) begin
					RS[`CLOG2(empty)] <= inst;
				end
				branchALUSignal 		   <= `INVALID;
				branchALU_CDB_out_RSnum    <= 0;
				branchALU_CDB_out_result   <= 0;
				branchALU_CDB_out_offset   <= `addrWidth'b0;
				if (ready) begin
					i = `CLOG2(ready);
					branchALUSignal <= `VALID;
					branchALU_CDB_out_offset <= RS[i][`branchALUOffsetRange];
					branchALU_CDB_out_RSnum  <= i;
					case (RS[i][`branchALUOpRange])
						`BEQ  : branchALU_CDB_out_result <= RS[i][`branchALUData1Range]          == RS[i][`branchALUData2Range];
						`BNE  : branchALU_CDB_out_result <= RS[i][`branchALUData1Range]          != RS[i][`branchALUData2Range];
						`BLT  : branchALU_CDB_out_result <= $signed(RS[i][`branchALUData1Range]) <  $signed(RS[i][`branchALUData2Range]);
						`BGE  : branchALU_CDB_out_result <= $signed(RS[i][`branchALUData1Range]) >= $signed(RS[i][`branchALUData2Range]);
						`BLTU : branchALU_CDB_out_result <= RS[i][`branchALUData1Range]          <  RS[i][`branchALUData2Range];
						`BGEU : branchALU_CDB_out_result <= RS[i][`branchALUData1Range]          >= RS[i][`branchALUData2Range];
						default : ;
					endcase
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
					branchALUSignal <= `INVALID;
					RS[branchALU_CDB_RSnum] <= {(`branchALUWidth){1'b0}}; 
				end
				/*
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
				*/
			end
		end
	end
endmodule
