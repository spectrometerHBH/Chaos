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

	wire [`addrWidth - 1 : 0] PC_IF;
	wire [`instWidth - 1 : 0] IF_ID_inst;
	wire IF_IFID_stall;
	wire IF_PC_stall;
	wire alu_IF_free;
	wire rob_IF_free;
	wire jump_complete;
	wire branch_complete;
	IFetcher IF(
		clk, rst, 
		PC_IF,
		ICache_rw_flag,
		ICache_addr,
		ICache_write_data,
		ICache_write_mask,
		ICache_read_data,
		ICache_busy,
		ICache_done,
		IF_IFID_stall,
		IF_ID_inst,
		IF_PC_stall,
		alu_IF_free,
		rob_IF_free,
		jump_complete,
		branch_complete
	);

	wire [`addrWidth - 1 : 0] PC_IFID;
	wire jump_dest_valid;
	wire [`addrWidth - 1 : 0] jump_dest;
	wire branch_offset_valid;
	wire [`addrWidth - 1 : 0] branch_offset;
	PC PC(
		clk, rst, 
		IF_PC_stall,
		PC_IF,
		PC_IFID,
		jump_dest_valid,
		jump_dest,
		branch_offset_valid,
		branch_offset
	);

	wire IF_ID_valid;
	wire [`instWidth - 1 : 0] IF_ID_inst_out;
	wire [`addrWidth - 1 : 0] IF_ID_pc_out;
	IF_ID IF_ID(
		clk, rst, 
		IF_IFID_stall,
		IF_ID_inst,
		IF_ID_valid,
		IF_ID_inst_out,
		IF_ID_pc_out,
		PC_IFID
	);

	wire ID_ALU_enable;
	wire [`aluWidth - 1 : 0] ID_ALU_data;
	wire [`addrWidth - 1 : 0] ID_ALU_PC;
	wire ID_branchALU_enable;
	wire [`branchALUWidth - 1 : 0] ID_branchALU_data;
	wire ID_ROB_tag1_ready;
	wire ID_ROB_tag2_ready;
	wire ID_ROB_tagd_ready;
	wire [`tagWidth  - 2 : 0] ID_ROB_robtail;
	wire [`dataWidth - 1 : 0] ID_ROB_data1;
	wire [`dataWidth - 1 : 0] ID_ROB_data2;
	wire [`dataWidth - 1 : 0] ID_ROB_datad;
	wire ID_ROB_enable;
	wire [`robWidth  - 1 : 0] ID_ROB_data;
	wire [`tagWidth  - 1 : 0] ID_ROB_tagcheck1;
	wire [`tagWidth  - 1 : 0] ID_ROB_tagcheck2;
	wire [`tagWidth  - 1 : 0] ID_ROB_tagcheckd;
	wire [`tagWidth  - 1 : 0] ID_reg_tag1; 
	wire [`tagWidth  - 1 : 0] ID_reg_tag2;
	wire [`tagWidth  - 1 : 0] ID_reg_tagd;
	wire [`dataWidth - 1 : 0] ID_reg_data1;
	wire [`dataWidth - 1 : 0] ID_reg_data2;
	wire [`dataWidth - 1 : 0] ID_reg_datad;
	wire [`regWidth  - 1 : 0] ID_reg_addr1;
	wire [`regWidth  - 1 : 0] ID_reg_addr2;
	wire [`regWidth  - 1 : 0] ID_reg_addrd;
	wire ID_reg_enable;
	wire [`regWidth  - 1 : 0] ID_reg_tagaddr;
	wire [`tagWidth  - 1 : 0] ID_reg_tag;

	Decoder ID(
		clk, rst, 
		IF_ID_valid,
		IF_ID_inst_out,
		PC_IFID,
		ID_ALU_enable,
		ID_ALU_data,
		ID_ALU_PC,
		ID_branchALU_enable,
		ID_branchALU_data,
		ID_ROB_tag1_ready,
		ID_ROB_tag2_ready,
		ID_ROB_tagd_ready,
		ID_ROB_robtail,
		ID_ROB_data1,
		ID_ROB_data2,
		ID_ROB_datad,
		ID_ROB_enable,
		ID_ROB_data,
		ID_ROB_tagcheck1,
		ID_ROB_tagcheck2,
		ID_ROB_tagcheckd,
		ID_reg_tag1,
		ID_reg_tag2,
		ID_reg_tagd,
		ID_reg_data1,
		ID_reg_data2,
		ID_reg_datad,
		ID_reg_addr1,
		ID_reg_addr2,
		ID_reg_addrd,
		ID_reg_enable,
		ID_reg_tagaddr,
		ID_reg_tag
	);

	wire ALU_ALUCDB_alufinish;
	wire [`aluRSWidth - 1 : 0] ALU_ALUCDB_rsnum;
	wire [`tagWidth   - 1 : 0] ALU_ALUCDB_tag;
	wire [`dataWidth  - 1 : 0] ALU_ALUCDB_data;
	wire ALU_ALUCDB_alusignal;
	wire [`aluRSWidth - 1 : 0] ALU_ALUCDB_outrsnum;
	wire [`tagWidth   - 1 : 0] ALU_ALUCDB_outtag;
	wire [`dataWidth  - 1 : 0] ALU_ALUCDB_outdata;
	wire [`addrWidth  - 1 : 0] ALU_ALUCDB_outdest;
	wire 					   ALU_ALUCDB_PC_valid;	
	ALU alu(
		clk, rst, exclk,
		alu_IF_free,
		ID_ALU_enable,
		ID_ALU_data,
		ID_ALU_PC,
		ALU_ALUCDB_alufinish,
		ALU_ALUCDB_rsnum,
		ALU_ALUCDB_tag,
		ALU_ALUCDB_data,
		ALU_ALUCDB_alusignal,
		ALU_ALUCDB_outrsnum,
		ALU_ALUCDB_outtag,
		ALU_ALUCDB_outdata,
		ALU_ALUCDB_outdest,
		ALU_ALUCDB_PC_valid
	);	

	wire branchALU_ALUCDB_valid;
	wire [`tagWidth   - 1 : 0] branchALU_ALUCDB_tag;
	wire [`dataWidth  - 1 : 0] branchALU_ALUCDB_data;
	wire 							   branchALUFinish;
	wire [`branchALURSWidth  - 1 : 0]  branchALU_CDB_RSnum;
	wire 							   branchALUSignal;
	wire [`branchALURSWidth   - 1 : 0] branchALU_CDB_out_RSnum;
	wire 						       branchALU_CDB_out_result;
	wire [`addrWidth          - 1 : 0] branchALU_CDB_out_offset;
	branchALU branchalu(
		clk, rst, exclk,
		ID_branchALU_enable,
		ID_branchALU_data,
		branchALU_ALUCDB_valid,
		branchALU_ALUCDB_tag,
		branchALU_ALUCDB_data,
		branchALUFinish,
		branchALU_CDB_RSnum,
		branchALUSignal,
		branchALU_CDB_out_RSnum,
		branchALU_CDB_out_result,
		branchALU_CDB_out_offset
	);

	wire ALUCDB_ROB_valid;
	wire [`tagWidth  - 1 : 0] ALUCDB_ROB_tag;
	wire [`dataWidth - 1 : 0] ALUCDB_ROB_data;
	ALU_CDB alu_cdb(
		clk, rst,
		ALU_ALUCDB_alusignal,
		ALU_ALUCDB_outrsnum,
		ALU_ALUCDB_outtag,
		ALU_ALUCDB_outdata,
		ALU_ALUCDB_outdest,
		ALU_ALUCDB_PC_valid,
		ALU_ALUCDB_alufinish,
		ALU_ALUCDB_rsnum,
		ALU_ALUCDB_tag,
		ALU_ALUCDB_data,
		ALUCDB_ROB_valid,
		ALUCDB_ROB_tag,
		ALUCDB_ROB_data,
		branchALU_ALUCDB_valid,
		branchALU_ALUCDB_tag,
		branchALU_ALUCDB_data,
		jump_dest_valid,
		jump_dest,
		jump_complete
	);

	branchALU_CDB branchalu_cdb(
		clk, rst,
		branchALUSignal,
		branchALU_CDB_out_RSnum,
		branchALU_CDB_out_result,
		branchALU_CDB_out_offset,
		branchALUFinish,
		branchALU_CDB_RSnum,
		branch_offset_valid,
		branch_offset,
		branch_complete
	);

	wire ROB_reg_enable;
	wire [`regWidth  - 1 : 0] ROB_reg_name;
	wire [`dataWidth - 1 : 0] ROB_reg_data;
	wire [`tagWidth  - 1 : 0] ROB_reg_tag;
	ROB rob(
		clk, rst, 
		ID_ROB_enable,
		ID_ROB_data,
		ID_ROB_tagcheck1,
		ID_ROB_tagcheck2,
		ID_ROB_tagcheckd,
		ID_ROB_robtail,
		ID_ROB_tag1_ready,
		ID_ROB_tag2_ready,
		ID_ROB_tagd_ready,
		ID_ROB_data1,
		ID_ROB_data2,
		ID_ROB_datad,
		ALUCDB_ROB_valid,
		ALUCDB_ROB_tag,
		ALUCDB_ROB_data,
		rob_IF_free,
		ROB_reg_enable,
		ROB_reg_name,
		ROB_reg_data,
		ROB_reg_tag
	);

	Regfile regfile(
		clk, rst, 
		ROB_reg_enable,
		ROB_reg_name,
		ROB_reg_data,
		ROB_reg_tag,
		ID_reg_enable,
		ID_reg_tagaddr,
		ID_reg_tag,
		ID_reg_addr1,
		ID_reg_tag1,
		ID_reg_data1,
		ID_reg_addr2,
		ID_reg_tag2,
		ID_reg_data2,
		ID_reg_addrd,
		ID_reg_tagd,
		ID_reg_datad
	);
endmodule