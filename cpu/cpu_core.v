`timescale 1ns/1ps

`include "defines.v"

module cpu_core(
	input wire clk,
	input wire rst,
	input wire exclk,
	//output to memory_controller
	output wire [1 * `rw_flagWidth - 1 : 0] rw_flag,
	output wire [1 * `addrWidth    - 1 : 0] addr,
	input  wire [1 * `dataWidth    - 1 : 0] read_data,
	output wire [1 * `dataWidth    - 1 : 0] write_data,
	output wire [1 * `maskWidth    - 1 : 0] write_mask,
	input  wire busy,
	input  wire done
);

	wire [1              : 0] ICache_rw_flag;
	wire [`addrWidth - 1 : 0] ICache_addr;	
	wire [`dataWidth - 1 : 0] ICache_read_data;
	wire [`dataWidth - 1 : 0] ICache_write_data;
	wire [`maskWidth - 1 : 0] ICache_write_mask;
	wire ICache_busy;
	wire ICache_done; 

	cache ICache(
		clk, rst, 
		ICache_rw_flag,
		ICache_addr,
		ICache_read_data,
		ICache_write_data,
		ICache_write_mask,
		ICache_busy,
		ICache_done,
		0,
		32'b0,
		rw_flag,
		addr,
		read_data,
		write_data,
		write_mask,
		busy,
		done
	);

	wire PC_IFID_enable;
	wire [`addrWidth - 1 : 0] PC_IFID_PC;
	wire [`instWidth - 1 : 0] PC_IFID_inst;
	wire jump_dest_valid;
	wire [`addrWidth - 1 : 0] jump_dest;
	wire branch_offset_valid;
	wire [`addrWidth - 1 : 0] branch_offset;
	wire alu_PC_free;
	wire rob_PC_free;
	
	PC pc(
		clk, rst, 
		PC_IFID_enable,
		PC_IFID_PC,
		PC_IFID_inst,
		jump_dest_valid,
		jump_dest,
		branch_offset_valid,
		branch_offset,
		ICache_rw_flag,
		ICache_addr,
		ICache_write_data,
		ICache_write_mask,
		ICache_read_data,
		ICache_busy,
		ICache_done,
		alu_PC_free,
		rob_PC_free
	);

    wire IF_ID_Decoder_valid;
    wire [`instWidth - 1 : 0] IF_ID_Decoder_inst_output;
    wire [`addrWidth - 1 : 0] IF_ID_Decoder_inst_pc;
	IF_ID IF_ID(
		clk, rst, 
		PC_IFID_enable,
		PC_IFID_PC,
		PC_IFID_inst,
		IF_ID_Decoder_valid,
		IF_ID_Decoder_inst_output,
		IF_ID_Decoder_inst_pc
	);
	
    wire Decoder_ALU_aluEnable;
    wire [`aluWidth - 1 : 0] Decoder_ALU_aluData;
    wire [`addrWidth - 1 : 0] Decoder_ALU_inst_PC_out;
    wire Decoder_branchALU_branchALUEnable;
    wire [`branchALUWidth - 1 : 0] Decoder_branchALU_branchALUData;
    wire Decoder_ROB_tag1Ready;
    wire Decoder_ROB_tag2Ready;
    wire Decoder_ROB_tagdReady;
    wire [`tagWidth  - 2 : 0] Decoder_ROB_ROBtail;
    wire [`dataWidth - 1 : 0] Decoder_ROB_robData1;
    wire [`dataWidth - 1 : 0] Decoder_ROB_robData2;
    wire [`dataWidth - 1 : 0] Decoder_ROB_robDatad;
    wire Decoder_ROB_robEnable;
    wire [`robWidth - 1 : 0] Decoder_ROB_robData;
    wire [`tagWidth - 1 : 0] Decoder_ROB_tagCheck1;
    wire [`tagWidth - 1 : 0] Decoder_ROB_tagCheck2;
    wire [`tagWidth - 1 : 0] Decoder_ROB_tagCheckd;
    wire [`tagWidth - 1 : 0] Decoder_reg_regTag1;
    wire [`tagWidth - 1 : 0] Decoder_reg_regTag2;
    wire [`tagWidth - 1 : 0] Decoder_reg_regTagd;
    wire [`dataWidth - 1 : 0] Decoder_reg_regData1;
    wire [`dataWidth - 1 : 0] Decoder_reg_regData2;
    wire [`dataWidth - 1 : 0] Decoder_reg_regDatad;
    wire [`regWidth - 1 : 0] Decoder_reg_regAddr1;
    wire [`regWidth - 1 : 0] Decoder_reg_regAddr2;
    wire [`regWidth - 1 : 0] Decoder_reg_regAddrd;
    wire Decoder_reg_regEnable;
    wire [`regWidth - 1 : 0] Decoder_reg_regTagAddr;
    wire [`tagWidth - 1 : 0] Decoder_reg_regTag;
    	
	Decoder decoder(
	   clk, rst,
	   IF_ID_Decoder_valid,
	   IF_ID_Decoder_inst_output,
	   IF_ID_Decoder_inst_pc,
	   Decoder_ALU_aluEnable,
	   Decoder_ALU_aluData,
	   Decoder_ALU_inst_PC_out,
	   Decoder_branchALU_branchALUEnable,
	   Decoder_branchALU_branchALUData,
	   Decoder_ROB_tag1Ready,
	   Decoder_ROB_tag2Ready,
	   Decoder_ROB_tagdReady,
	   Decoder_ROB_ROBtail,
	   Decoder_ROB_robData1,
	   Decoder_ROB_robData2,
	   Decoder_ROB_robDatad,
	   Decoder_ROB_robEnable,
	   Decoder_ROB_robData,
	   Decoder_ROB_tagCheck1,
	   Decoder_ROB_tagCheck2,
	   Decoder_ROB_tagCheckd,
	   Decoder_reg_regTag1,
	   Decoder_reg_regTag2,
	   Decoder_reg_regTagd,
	   Decoder_reg_regData1,
	   Decoder_reg_regData2,
	   Decoder_reg_regDatad,
	   Decoder_reg_regAddr1,
	   Decoder_reg_regAddr2,
	   Decoder_reg_regAddrd,
	   Decoder_reg_regEnable,
	   Decoder_reg_regTagAddr,
	   Decoder_reg_regTag
	);
	
    wire ALU_ALUCDB_aluFinish;
    wire [`aluRSWidth - 1 : 0] ALU_ALUCDB_ALU_CDB_RSnum;
    wire [`tagWidth   - 1 : 0] ALU_ALUCDB_ALU_CDB_tag;
    wire [`dataWidth  - 1 : 0] ALU_ALUCDB_ALU_CDB_data;
    wire ALU_ALUCDB_aluSignal;
    wire [`aluRSWidth - 1 : 0] ALU_ALUCDB_ALU_CDB_out_RSnum;
    wire [`tagWidth   - 1 : 0] ALU_ALUCDB_ALU_CDB_out_tag;
    wire [`dataWidth  - 1 : 0] ALU_ALUCDB_ALU_CDB_out_data;
    wire [`addrWidth  - 1 : 0] ALU_ALUCDB_ALU_CDB_out_offset;
    wire                       ALU_ALUCDB_ALU_CDB_PC_valid;
	ALU alu(
	   clk, rst, exclk,
	   alu_PC_free,
	   Decoder_ALU_aluEnable,
	   Decoder_ALU_aluData,
	   Decoder_ALU_inst_PC_out,
	   ALU_ALUCDB_aluFinish,
	   ALU_ALUCDB_ALU_CDB_RSnum,
	   ALU_ALUCDB_ALU_CDB_tag,
	   ALU_ALUCDB_ALU_CDB_data,
	   ALU_ALUCDB_aluSignal,
	   ALU_ALUCDB_ALU_CDB_out_RSnum,
	   ALU_ALUCDB_ALU_CDB_out_tag,
	   ALU_ALUCDB_ALU_CDB_out_data,
	   ALU_ALUCDB_ALU_CDB_out_offset,
	   ALU_ALUCDB_ALU_CDB_PC_valid
	);

	wire ALUCDB_ROB_valid_ROB;
	wire [`tagWidth  - 1 : 0] ALUCDB_ROB_robTagOut;
	wire [`dataWidth - 1 : 0] ALUCDB_ROB_robDataOut;
	wire ALUCDB_BranchALU_valid_branch;
	wire [`tagWidth  - 1 : 0] ALUCDB_BranchALU_branchALUTagOut;
	wire [`dataWidth - 1 : 0] ALUCDB_BranchALU_branchALUDataOut;
	
	ALU_CDB alucdb(
		clk, rst,
		ALU_ALUCDB_aluSignal,
		ALU_ALUCDB_ALU_CDB_out_RSnum,
		ALU_ALUCDB_ALU_CDB_out_tag,
		ALU_ALUCDB_ALU_CDB_out_data,
		ALU_ALUCDB_ALU_CDB_out_offset,
		ALU_ALUCDB_ALU_CDB_PC_valid,
		ALU_ALUCDB_aluFinish,
		ALU_ALUCDB_ALU_CDB_RSnum,
		ALU_ALUCDB_ALU_CDB_tag,
		ALU_ALUCDB_ALU_CDB_data,
		ALUCDB_ROB_valid_ROB,
		ALUCDB_ROB_robTagOut,
		ALUCDB_ROB_robDataOut,
		ALUCDB_BranchALU_valid_branch,
		ALUCDB_BranchALU_branchALUTagOut,
		ALUCDB_BranchALU_branchALUDataOut,
		jump_dest_valid,
		jump_dest
	);

	wire branchALU_branchALU_CDB_branchALUFinish;
	wire [`branchALURSWidth   - 1 : 0] branchALU_branchALU_CDB_branchALU_CDB_RSnum;
	wire 							   branchALU_branchALU_CDB_branchALUSignal;
	wire [`branchALURSWidth   - 1 : 0] branchALU_branchALU_CDB_branchALU_CDB_out_RSnum;
	wire 						        branchALU_branchALU_CDB_branchALU_CDB_out_result;
	wire [`addrWidth          - 1 : 0] branchALU_branchALU_CDB_branchALU_CDB_out_offset;
	branchALU branchalu(
		clk, rst, exclk,
		Decoder_branchALU_branchALUEnable,
		Decoder_branchALU_branchALUData,
		ALUCDB_BranchALU_valid_branch,
		ALUCDB_BranchALU_branchALUTagOut,
		ALUCDB_BranchALU_branchALUDataOut,
		branchALU_branchALU_CDB_branchALUFinish,
		branchALU_branchALU_CDB_branchALU_CDB_RSnum,
		branchALU_branchALU_CDB_branchALUSignal,
		branchALU_branchALU_CDB_branchALU_CDB_out_RSnum,
		branchALU_branchALU_CDB_branchALU_CDB_out_result,
		branchALU_branchALU_CDB_branchALU_CDB_out_offset
	);

	branchALU_CDB branchalu_cdb(
		clk, rst,
		branchALU_branchALU_CDB_branchALUSignal,
		branchALU_branchALU_CDB_branchALU_CDB_out_RSnum,
		branchALU_branchALU_CDB_branchALU_CDB_out_result,
		branchALU_branchALU_CDB_branchALU_CDB_out_offset,
		branchALU_branchALU_CDB_branchALUFinish,
		branchALU_branchALU_CDB_branchALU_CDB_RSnum,
	    branch_offset_valid,
        branch_offset
	);

    //output to Regfile
    wire ROB_reg_regfileEnable;
    wire [`regWidth  - 1 : 0] ROB_reg_rob_reg_name;
    wire [`dataWidth - 1 : 0] ROB_reg_rob_reg_data;
    wire [`tagWidth  - 1 : 0] ROB_reg_rob_reg_tag;
    ROB rob(
    	clk, rst, exclk,
    	Decoder_ROB_robEnable,
    	Decoder_ROB_robData,
    	Decoder_ROB_tagCheck1,
    	Decoder_ROB_tagCheck2,
    	Decoder_ROB_tagCheckd,
    	Decoder_ROB_ROBtail,
    	Decoder_ROB_tag1Ready,
    	Decoder_ROB_tag2Ready,
    	Decoder_ROB_tagdReady,
    	Decoder_ROB_robData1,
    	Decoder_ROB_robData2,
    	Decoder_ROB_robDatad,
    	ALUCDB_ROB_valid_ROB,
    	ALUCDB_ROB_robTagOut,
    	ALUCDB_ROB_robDataOut,
    	rob_PC_free,
    	ROB_reg_regfileEnable,
    	ROB_reg_rob_reg_name,
    	ROB_reg_rob_reg_data,
    	ROB_reg_rob_reg_tag
    );

    Regfile regfile(
    	clk, rst,
    	ROB_reg_regfileEnable,
    	ROB_reg_rob_reg_name,
    	ROB_reg_rob_reg_data,
    	ROB_reg_rob_reg_tag,
    	Decoder_reg_regEnable,
    	Decoder_reg_regTagAddr,
    	Decoder_reg_regTag,
    	Decoder_reg_regAddr1,
    	Decoder_reg_regTag1,
    	Decoder_reg_regData1,
    	Decoder_reg_regAddr2,
    	Decoder_reg_regTag2,
    	Decoder_reg_regData2,
    	Decoder_reg_regAddrd,
    	Decoder_reg_regTagd,
    	Decoder_reg_regDatad
    );
endmodule