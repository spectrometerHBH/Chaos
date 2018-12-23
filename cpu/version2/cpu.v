// RISCV32I CPU top module
// port modification allowed for debugging purposes

`timescale 1ns/1ps

`include "defines.vh"

module cpu(
  input  wire                 clk,			// system clock signal
  input  wire                 rst,			// reset signal
  input  wire				  rdy,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)

  output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles, write takes 1 cycle
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17]==1)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    wire [1 : 0]              core_mcu_rw_flag[1 : 0];
    wire [`addrWidth - 1 : 0] core_mcu_addr[1 : 0];
    wire [1 : 0]              core_mcu_len[1 : 0];
    wire [`dataWidth - 1 : 0] core_mcu_data[1 : 0];
    wire [`addrWidth - 1 : 0] core_mcu_PC2;
    wire [`dataWidth - 1 : 0] mcu_core_data[1 : 0];
    wire [1 : 0]              mcu_core_busy;
    wire [1 : 0]              mcu_core_done;
    wire                      cache_hit1;
    wire [`instWidth - 1 : 0] cache_data1;
    wire                      cache_hit2;
    wire [`instWidth - 1 : 0] cache_data2;
    wire                      stall;
    wire                      clear;
    mem_ctrl mcu(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .rw_flag({core_mcu_rw_flag[1], core_mcu_rw_flag[0]}),
        .addr({core_mcu_addr[1], core_mcu_addr[0]}),
        .len({core_mcu_len[1], core_mcu_len[0]}),
        .data_in({core_mcu_data[1], core_mcu_data[0]}),
        .PC_2(core_mcu_PC2),
        .data_out({mcu_core_data[1], mcu_core_data[0]}),
        .busy(mcu_core_busy),
        .done(mcu_core_done),
        .ram_rw_flag(mem_wr),
        .ram_addr(mem_a),
        .ram_data_out(mem_dout),
        .ram_data_in(mem_din),
        .cache_hit1(cache_hit1),
        .cache_inst1(cache_data1),
        .cache_hit2(cache_hit2),
        .cache_inst2(cache_data2)        
    );

    
    wire                      if_dec1_en;
    wire [`addrWidth - 1 : 0] if_dec1_pc;
    wire [`instWidth - 1 : 0] if_dec1_inst;
    wire [`addrWidth - 1 : 0] dec1_if_taken;
    wire                      if_dec2_en;
    wire [`addrWidth - 1 : 0] if_dec2_pc;
    wire [`instWidth - 1 : 0] if_dec2_inst;  
    wire [`addrWidth - 1 : 0] dec2_if_taken;
    wire                      alu_if_jump_dest_valid1;
    wire [`addrWidth - 1 : 0] alu_if_jump_dest1;
    wire                      alu_if_jump_dest_valid2;
    wire [`addrWidth - 1 : 0] alu_if_jump_dest2;
    wire                      alu_if_jump_dest_valid;
    wire [`addrWidth - 1 : 0] alu_if_jump_dest;    
    wire [`addrWidth - 1 : 0] rob_if_target;
    wire                      alu_free;
    wire                      br_free;
    wire                      ls_free;
    wire                      rob_free;
    
    assign stall = (!alu_free) || (!br_free) || (!ls_free) || (!rob_free);
    assign alu_if_jump_dest_valid = alu_if_jump_dest_valid1 | alu_if_jump_dest_valid2;
    assign alu_if_jump_dest = alu_if_jump_dest_valid1 ? alu_if_jump_dest1 : alu_if_jump_dest2;
    
    wire if_pdt_en, pdt_if_predict1, pdt_if_predict2, if_pdt_mux;
    wire if_dec_predict1, if_dec_predict2;
    
    PC fetcher(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .predictor_en(if_pdt_en),
        .predictor_mux(if_pdt_mux),
        .predict1(pdt_if_predict1),
        .predict2(pdt_if_predict2),
        .Decoder_enable1(if_dec1_en),
        .PC_Decoder1(if_dec1_pc),
        .inst_Decoder1(if_dec1_inst),
        .predict_Decoder1(if_dec_predict1),
        .Decoder1_taken(dec1_if_taken),
        .Decoder_enable2(if_dec2_en),
        .PC_Decoder2(if_dec2_pc),
        .inst_Decoder2(if_dec2_inst),
        .predict_Decoder2(if_dec_predict2),
        .Decoder2_taken(dec2_if_taken),
        .jump_dest_valid(alu_if_jump_dest_valid),
        .jump_dest(alu_if_jump_dest),
        .rw_flag(core_mcu_rw_flag[0]),
        .PC(core_mcu_addr[0]),
        .len(core_mcu_len[0]),
        .next_PC(core_mcu_PC2),
        .read_data(mcu_core_data[0]),
        .mem_busy(mcu_core_busy[0]),
        .mem_done(mcu_core_done[0]),
        .cache_hit1(cache_hit1),
        .cache_data1(cache_data1),
        .cache_hit2(cache_hit2),
        .cache_data2(cache_data2),
        .stall(stall),
        .clear(clear),
        .true_target(rob_if_target)
    );
    
    wire rob_pdt_en, rob_pdt_choice;
    
    predictor GodKnows(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .insert_en(if_pdt_en),
        .mux(if_pdt_mux),
        .PC1(core_mcu_addr[0]),
        .PC2(core_mcu_PC2),
        .predict1(pdt_if_predict1),
        .predict2(pdt_if_predict2),
        .modify_en(rob_pdt_en),
        .clear(clear),
        .choice(rob_pdt_choice)    
    );
    
    wire                dec1_dp_en;
    wire [`classOpWidth - 1 : 0] classop_out1;
    wire [`newopWidth   - 1 : 0] newop_out1;
    wire [`addrWidth    - 1 : 0] inst_PC_out1;
    wire [`reg_sel - 1 : 0] rs1_out1;
    wire [`reg_sel - 1 : 0] rs2_out1;
    wire [`reg_sel - 1 : 0] rd_out1;
    wire [`addrWidth - 1 : 0] Imm_out1;
    wire [`addrWidth  - 1 : 0] UImm_out1;
    wire [`addrWidth  - 1 : 0] JImm_out1;
    wire [`addrWidth  - 1 : 0] BImm_out1;
    wire [`addrWidth  - 1 : 0] SImm_out1;
    wire                       lock_prefix_1;
    wire                       wr_rd_1;
    wire                       is_branch_1;
    wire                       dec_dp_predict1;
    Decoder decoder1(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .stall(stall),
        .predict(if_dec_predict1),
        .decoderEnable(if_dec1_en),
        .instToDecode(if_dec1_inst),
        .inst_PC(if_dec1_pc),
        .branch_predict(dec1_if_taken),
        .dispatch_enable(dec1_dp_en),
        .classop_out(classop_out1),
        .newop_out(newop_out1),
        .inst_PC_out(inst_PC_out1),
        .rs1_out(rs1_out1),
        .rs2_out(rs2_out1),
        .rd_out(rd_out1),
        .Imm_out(Imm_out1),
        .UImm_out(UImm_out1),
        .JImm_out(JImm_out1),
        .BImm_out(BImm_out1),
        .SImm_out(SImm_out1),
        .lock_prefix(lock_prefix_1),
        .wr_rd_out(wr_rd_1),
        .is_branch_out(is_branch_1),
        .predict_out(dec_dp_predict1)
    );
    
    wire                dec2_dp_en;
    wire [`classOpWidth - 1 : 0] classop_out2;
    wire [`newopWidth   - 1 : 0] newop_out2;
    wire [`addrWidth    - 1 : 0] inst_PC_out2;
    wire [`reg_sel - 1 : 0] rs1_out2;
    wire [`reg_sel - 1 : 0] rs2_out2;
    wire [`reg_sel - 1 : 0] rd_out2;
    wire [`addrWidth - 1 : 0] Imm_out2;
    wire [`addrWidth  - 1 : 0] UImm_out2;
    wire [`addrWidth  - 1 : 0] JImm_out2;
    wire [`addrWidth  - 1 : 0] BImm_out2;
    wire [`addrWidth  - 1 : 0] SImm_out2;
    wire                       lock_prefix_2;
    wire                       wr_rd_2;
    wire                       is_branch_2;
    wire                       dec_dp_predict2;

    Decoder decoder2(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .stall(stall),
        .predict(if_dec_predict2),
        .decoderEnable(if_dec2_en),
        .instToDecode(if_dec2_inst),
        .inst_PC(if_dec2_pc),
        .branch_predict(dec2_if_taken),
        .dispatch_enable(dec2_dp_en),
        .classop_out(classop_out2),
        .newop_out(newop_out2),
        .inst_PC_out(inst_PC_out2),
        .rs1_out(rs1_out2),
        .rs2_out(rs2_out2),
        .rd_out(rd_out2),
        .Imm_out(Imm_out2),
        .UImm_out(UImm_out2),
        .JImm_out(JImm_out2),
        .BImm_out(BImm_out2),
        .SImm_out(SImm_out2),
        .lock_prefix(lock_prefix_2),
        .wr_rd_out(wr_rd_2),
        .is_branch_out(is_branch_2),
        .predict_out(dec_dp_predict2)
    );
    
    wire [5 : 0] alu_busy;
    wire [5 : 0] alu_ready;
    wire [2 : 0] branch_busy_i;
    wire [2 : 0] branch_ready_i;
    wire [2 : 0] alu_free_1;
    wire [2 : 0] alu_free_2;
    wire [2 : 0] alu_ready_1;
    wire [2 : 0] alu_ready_2;
    wire [1 : 0] branch_free;
    wire [1 : 0] branch_ready;
    
    addr_table aoko(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .alu_busy(alu_busy),
        .alu_ready(alu_ready),
        .branch_busy_i(branch_busy_i),
        .branch_ready_i(branch_ready_i),
        .alu_free_1(alu_free_1),
        .alu_free_2(alu_free_2),
        .alu_ready_1(alu_ready_1),
        .alu_ready_2(alu_ready_2),
        .branch_free(branch_free),
        .branch_ready(branch_ready)
    );
    
    wire [`tagWidth - 1 : 0] reg_dp_tag1_1;
    wire [`tagWidth - 1 : 0] reg_dp_tag2_1;
    wire [`dataWidth - 1 : 0] reg_dp_data1_1;
    wire [`dataWidth - 1 : 0] reg_dp_data2_1;
    wire [`tagWidth - 1 : 0] reg_dp_tag1_2;
    wire [`tagWidth - 1 : 0] reg_dp_tag2_2;
    wire [`dataWidth - 1 : 0] reg_dp_data1_2;
    wire [`dataWidth - 1 : 0] reg_dp_data2_2;
    wire [`reg_sel - 1 : 0] dp_reg_regAddr1_1;
    wire [`reg_sel - 1 : 0] dp_reg_regAddr2_1;
    wire [`reg_sel - 1 : 0] dp_reg_regAddr1_2;
    wire [`reg_sel - 1 : 0] dp_reg_regAddr2_2;
    wire [`tagWidth - 1 : 0] dp_rob_tag1_1;
    wire [`tagWidth - 1 : 0] dp_rob_tag2_1;
    wire [`tagWidth - 1 : 0] dp_rob_tag1_2;
    wire [`tagWidth - 1 : 0] dp_rob_tag2_2;
    wire                     dp_rob_enable1;
    wire                     dp_rob_isbranch1;
    wire                     dp_rob_wr_rd1;
    wire [`reg_sel - 1 : 0]  dp_rob_dest1;
    wire                     dp_rob_enable2;
    wire                     dp_rob_isbranch2;
    wire                     dp_rob_wr_rd2;
    wire [`reg_sel - 1 : 0]  dp_rob_dest2;
    wire                     rob_dp_ready1_1;
    wire [`dataWidth - 1 : 0] rob_dp_data1_1;
    wire                     rob_dp_ready2_1;
    wire [`dataWidth - 1 : 0] rob_dp_data2_1;
    wire                     rob_dp_ready1_2;
    wire [`dataWidth - 1 : 0] rob_dp_data1_2;
    wire                     rob_dp_ready2_2;
    wire [`dataWidth - 1 : 0] rob_dp_data2_2; 
    wire  dp_alu_enable_1;
    wire  [`newopWidth - 1 : 0] dp_alu_op_1;
    wire  [`dataWidth  - 1 : 0] dp_alu_data1_1;
    wire  [`tagWidth   - 1 : 0] dp_alu_tag1_1;
    wire  [`dataWidth  - 1 : 0] dp_alu_data2_1;
    wire  [`tagWidth   - 1 : 0] dp_alu_tag2_1;
    wire  [`addrWidth  - 1 : 0] dp_alu_PC_1;
    wire  [`tagWidth   - 1 : 0] dp_alu_dest_1;
    wire  dp_alu_enable_2;
    wire  [`newopWidth - 1 : 0] dp_alu_op_2;
    wire  [`dataWidth  - 1 : 0] dp_alu_data1_2;
    wire  [`tagWidth   - 1 : 0] dp_alu_tag1_2;
    wire  [`dataWidth  - 1 : 0] dp_alu_data2_2;
    wire  [`tagWidth   - 1 : 0] dp_alu_tag2_2;
    wire  [`addrWidth  - 1 : 0] dp_alu_PC_2;
    wire  [`tagWidth   - 1 : 0] dp_alu_dest_2;
    wire  dp_branch_enable;
    wire  [`newopWidth - 1 : 0] dp_branch_op;
    wire  [`dataWidth  - 1 : 0] dp_branch_data1;
    wire  [`tagWidth   - 1 : 0] dp_branch_tag1;
    wire  [`dataWidth  - 1 : 0] dp_branch_data2;
    wire  [`tagWidth   - 1 : 0] dp_branch_tag2;
    wire  [`addrWidth  - 1 : 0] dp_branch_offset;
    wire  [`addrWidth  - 1 : 0] dp_branch_PC;
    wire  [`tagWidth   - 1 : 0] dp_branch_dest;
    wire dp_ls_enable1;
    wire [`newopWidth - 1 : 0] dp_ls_op_1;
    wire [`dataWidth  - 1 : 0] dp_ls_base_1;
    wire [`tagWidth   - 1 : 0] dp_ls_basetag_1;
    wire [`dataWidth  - 1 : 0] dp_ls_src_1;
    wire [`tagWidth   - 1 : 0] dp_ls_srctag_1;
    wire [`addrWidth  - 1 : 0] dp_ls_Imm_1;
    wire [`tagWidth   - 1 : 0] dp_ls_dest_1;
    wire dp_ls_enable2;
    wire [`newopWidth - 1 : 0] dp_ls_op_2;
    wire [`dataWidth  - 1 : 0] dp_ls_base_2;
    wire [`tagWidth   - 1 : 0] dp_ls_basetag_2;
    wire [`dataWidth  - 1 : 0] dp_ls_src_2;
    wire [`tagWidth   - 1 : 0] dp_ls_srctag_2;
    wire [`addrWidth  - 1 : 0] dp_ls_Imm_2;
    wire [`tagWidth   - 1 : 0] dp_ls_dest_2;
    wire dp_reg_enable1;
    wire [`reg_sel - 1 : 0] dp_reg_sel1;
    wire [`tagWidth - 1 : 0] dp_reg_tag1;
    wire dp_reg_enable2;
    wire [`reg_sel - 1 : 0] dp_reg_sel2;
    wire [`tagWidth - 1 : 0] dp_reg_tag2;
    wire [`rob_sel - 1 : 0] rob_free_1;
    wire [`rob_sel - 1 : 0] rob_free_2;
    
    Dispatcher dispatcher(
        .dispatch_enable1(dec1_dp_en),
        .classop1(classop_out1),
        .newop1(newop_out1),
        .inst_PC1(inst_PC_out1),
        .rs1_1(rs1_out1),
        .rs2_1(rs2_out1),
        .rd_1(rd_out1),
        .Imm_1(Imm_out1),
        .UImm_1(UImm_out1),
        .JImm_1(JImm_out1),
        .BImm_1(BImm_out1),
        .SImm_1(SImm_out1),
        .lock_prefix_1(lock_prefix_1),
        .wr_rd_1(wr_rd_1),
        .predict_1(dec_dp_predict1),
        .isbranch_1(is_branch_1),
        .dispatch_enable2(dec2_dp_en),
        .classop2(classop_out2),
        .newop2(newop_out2),
        .inst_PC2(inst_PC_out2),
        .rs1_2(rs1_out2),
        .rs2_2(rs2_out2),
        .rd_2(rd_out2),
        .Imm_2(Imm_out2),
        .UImm_2(UImm_out2),
        .JImm_2(JImm_out2),
        .BImm_2(BImm_out2),
        .SImm_2(SImm_out2),
        .lock_prefix_2(lock_prefix_2),
        .wr_rd_2(wr_rd_2),
        .predict_2(dec_dp_predict2),
        .isbranch_2(is_branch_2),
        .tag1_1_reg(reg_dp_tag1_1),
        .tag2_1_reg(reg_dp_tag2_1),
        .data1_1_reg(reg_dp_data1_1),
        .data2_1_reg(reg_dp_data2_1),
        .tag1_2_reg(reg_dp_tag1_2),
        .tag2_2_reg(reg_dp_tag2_2),
        .data1_2_reg(reg_dp_data1_2),
        .data2_2_reg(reg_dp_data2_2),
        .regAddr1_1(dp_reg_regAddr1_1),
        .regAddr2_1(dp_reg_regAddr2_1),
        .regAddr1_2(dp_reg_regAddr1_2),
        .regAddr2_2(dp_reg_regAddr2_2),
        .tag1_1_out(dp_rob_tag1_1),
        .tag2_1_out(dp_rob_tag2_1),
        .tag1_2_out(dp_rob_tag1_2),
        .tag2_2_out(dp_rob_tag2_2),
        .rob_enable1(dp_rob_enable1),
        .isbranch1(dp_rob_isbranch1),
        .wr_rd1(dp_rob_wr_rd1),
        .rob_dest1(dp_rob_dest1),
        .rob_enable2(dp_rob_enable2),
        .isbranch2(dp_rob_isbranch2),
        .wr_rd2(dp_rob_wr_rd2),
        .rob_dest2(dp_rob_dest2),
        .ready1_1(rob_dp_ready1_1),
        .data1_1_rob(rob_dp_data1_1),
        .ready2_1(rob_dp_ready2_1),
        .data2_1_rob(rob_dp_data2_1),
        .ready1_2(rob_dp_ready1_2),
        .data1_2_rob(rob_dp_data1_2),
        .ready2_2(rob_dp_ready2_2),
        .data2_2_rob(rob_dp_data2_2),
        .alu_enable_1(dp_alu_enable_1),
        .alu_op_1(dp_alu_op_1),
        .alu_data1_1(dp_alu_data1_1),
        .alu_tag1_1(dp_alu_tag1_1),
        .alu_data2_1(dp_alu_data2_1),
        .alu_tag2_1(dp_alu_tag2_1),
        .alu_PC_1(dp_alu_PC_1),
        .alu_dest_1(dp_alu_dest_1),
        .alu_enable_2(dp_alu_enable_2),
        .alu_op_2(dp_alu_op_2),
        .alu_data1_2(dp_alu_data1_2),
        .alu_tag1_2(dp_alu_tag1_2),
        .alu_data2_2(dp_alu_data2_2),
        .alu_tag2_2(dp_alu_tag2_2),
        .alu_PC_2(dp_alu_PC_2),
        .alu_dest_2(dp_alu_dest_2),
        .branch_enable(dp_branch_enable),
        .branch_op(dp_branch_op),
        .branch_data1(dp_branch_data1),
        .branch_tag1(dp_branch_tag1),
        .branch_data2(dp_branch_data2),
        .branch_tag2(dp_branch_tag2),
        .branch_offset(dp_branch_offset),
        .branch_PC(dp_branch_PC),
        .branch_dest(dp_branch_dest),
        .ls_enable1(dp_ls_enable1),
        .ls_op_1(dp_ls_op_1),
        .ls_base_1(dp_ls_base_1),
        .ls_basetag_1(dp_ls_basetag_1),
        .ls_src_1(dp_ls_src_1),
        .ls_srctag_1(dp_ls_srctag_1),
        .ls_Imm_1(dp_ls_Imm_1),
        .ls_dest_1(dp_ls_dest_1),
        .ls_enable2(dp_ls_enable2),
        .ls_op_2(dp_ls_op_2),
        .ls_base_2(dp_ls_base_2),
        .ls_basetag_2(dp_ls_basetag_2),
        .ls_src_2(dp_ls_src_2),
        .ls_srctag_2(dp_ls_srctag_2),
        .ls_Imm_2(dp_ls_Imm_2),
        .ls_dest_2(dp_ls_dest_2),
        .reg_enable1(dp_reg_enable1),
        .reg_sel1(dp_reg_sel1),
        .reg_tag1(dp_reg_tag1),
        .reg_enable2(dp_reg_enable2),
        .reg_sel2(dp_reg_sel2),
        .reg_tag2(dp_reg_tag2),
        .lock1({1'b0, rob_free_1}),
        .lock2({1'b0, rob_free_2})
    );
    
    wire ex_alu_en1;
    wire [`tagWidth - 1 : 0] ex_alu_rst_tag1;
    wire [`dataWidth - 1 : 0] ex_alu_rst_data1;
    wire [`reg_sel  - 1 : 0] ex_alu_rst_reg1;
    wire ex_alu_en2;
    wire [`tagWidth - 1 : 0] ex_alu_rst_tag2;
    wire [`dataWidth - 1 : 0] ex_alu_rst_data2;
    wire [`reg_sel  - 1 : 0] ex_alu_rst_reg2;
    wire ex_mem_en;
    wire [`tagWidth - 1 : 0] ex_mem_rst_tag;
    wire [`dataWidth - 1 : 0] ex_mem_rst_data;
    wire [`reg_sel  - 1 : 0] ex_mem_rst_reg;
    
    wire alu_ex_en_1;
    wire [`dataWidth - 1 : 0] alu_exsrc1_1;
    wire [`dataWidth - 1 : 0] alu_exsrc2_1;
    wire [`addrWidth - 1 : 0] alu_expc_1;
    wire [`newopWidth - 1 : 0] alu_exaluop_1;
    wire [`tagWidth - 1 : 0]  alu_exdest_1;
    wire alu_ex_en_2;
    wire [`dataWidth - 1 : 0] alu_exsrc1_2;
    wire [`dataWidth - 1 : 0] alu_exsrc2_2;
    wire [`addrWidth - 1 : 0] alu_expc_2;
    wire [`newopWidth - 1 : 0] alu_exaluop_2;
    wire [`tagWidth - 1 : 0]  alu_exdest_2;
    
    rs_alu rs_alu(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .alu_enable_1(dp_alu_enable_1),
        .alu_op_1(dp_alu_op_1),
        .alu_data1_1(dp_alu_data1_1),
        .alu_tag1_1(dp_alu_tag1_1),
        .alu_data2_1(dp_alu_data2_1),
        .alu_tag2_1(dp_alu_tag2_1),
        .alu_PC_1(dp_alu_PC_1),
        .alu_dest_1(dp_alu_dest_1),
        .alu_enable_2(dp_alu_enable_2),
        .alu_op_2(dp_alu_op_2),
        .alu_data1_2(dp_alu_data1_2),
        .alu_tag1_2(dp_alu_tag1_2),
        .alu_data2_2(dp_alu_data2_2),
        .alu_tag2_2(dp_alu_tag2_2),
        .alu_PC_2(dp_alu_PC_2),
        .alu_dest_2(dp_alu_dest_2),
        .en_alu_rst1(ex_alu_en1),
        .alu_rst_tag1(ex_alu_rst_tag1),
        .alu_rst_data1(ex_alu_rst_data1),
        .en_alu_rst2(ex_alu_en2),
        .alu_rst_tag2(ex_alu_rst_tag2),
        .alu_rst_data2(ex_alu_rst_data2),
        .en_mem_rst(ex_mem_en),
        .mem_rst_tag(ex_mem_rst_tag),
        .mem_rst_data(ex_mem_rst_data),
        .ex_alu_en1(alu_ex_en_1),
        .exsrc1_out1(alu_exsrc1_1),
        .exsrc2_out1(alu_exsrc2_1),
        .expc_out1(alu_expc_1),
        .exaluop_out1(alu_exaluop_1),
        .exdest_out1(alu_exdest_1),
        .ex_alu_en2(alu_ex_en_2),
        .exsrc1_out2(alu_exsrc1_2),
        .exsrc2_out2(alu_exsrc2_2),
        .expc_out2(alu_expc_2),
        .exaluop_out2(alu_exaluop_2),
        .exdest_out2(alu_exdest_2),
        .rs_alu_free(alu_free),
        .busy(alu_busy),
        .ready(alu_ready),
        .stall(stall),
        .alloc_addr_1(alu_free_1),
        .alloc_addr_2(alu_free_2),
        .issue_addr_1(alu_ready_1),
        .issue_addr_2(alu_ready_2)
    );
    
    ex_alu ex_alu_1(
        .ex_alu_en(alu_ex_en_1),
        .exsrc1(alu_exsrc1_1),
        .exsrc2(alu_exsrc2_1),
        .expc(alu_expc_1),
        .exaluop(alu_exaluop_1),
        .exdest(alu_exdest_1),
        .en_rst(ex_alu_en1),
        .rst_data(ex_alu_rst_data1),
        .rst_tag(ex_alu_rst_tag1),
        .jump_dest_valid(alu_if_jump_dest_valid1),
        .jump_dest(alu_if_jump_dest1)
    );
    
    ex_alu ex_alu_2(
        .ex_alu_en(alu_ex_en_2),
        .exsrc1(alu_exsrc1_2),
        .exsrc2(alu_exsrc2_2),
        .expc(alu_expc_2),
        .exaluop(alu_exaluop_2),
        .exdest(alu_exdest_2),
        .en_rst(ex_alu_en2),
        .rst_data(ex_alu_rst_data2),
        .rst_tag(ex_alu_rst_tag2),
        .jump_dest_valid(alu_if_jump_dest_valid2),
        .jump_dest(alu_if_jump_dest2)
    );
    
    wire branch_ex_en;
    wire [`dataWidth - 1 : 0] branch_exsrc1;
    wire [`dataWidth - 1 : 0] branch_exsrc2;
    wire [`addrWidth - 1 : 0] branch_expc;
    wire [`newopWidth - 1 : 0] branch_exaluop;
    wire [`addrWidth - 1 : 0]  branch_exoffset;
    wire [`tagWidth  - 1 : 0] branch_exdest;
    
    rs_branch rs_branch(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .branch_enable(dp_branch_enable),
        .branch_op(dp_branch_op),
        .branch_data1(dp_branch_data1),
        .branch_tag1(dp_branch_tag1),
        .branch_data2(dp_branch_data2),
        .branch_tag2(dp_branch_tag2),
        .branch_PC(dp_branch_PC),
        .branch_offset(dp_branch_offset),
        .branch_dest(dp_branch_dest),
        .en_alu_rst1(ex_alu_en1),
        .alu_rst_tag1(ex_alu_rst_tag1),
        .alu_rst_data1(ex_alu_rst_data1),
        .en_alu_rst2(ex_alu_en2),
        .alu_rst_tag2(ex_alu_rst_tag2),
        .alu_rst_data2(ex_alu_rst_data2),
        .en_mem_rst(ex_mem_en),
        .mem_rst_tag(ex_mem_rst_tag),
        .mem_rst_data(ex_mem_rst_data),
        .ex_branch_en(branch_ex_en),
        .exsrc1_out(branch_exsrc1),
        .exsrc2_out(branch_exsrc2),
        .expc_out(branch_expc),
        .exaluop_out(branch_exaluop),
        .exoffset_out(branch_exoffset),
        .exdest_out(branch_exdest),
        .stall(stall),
        .rs_branch_free(br_free),
        .busy(branch_busy_i),
        .ready(branch_ready_i),
        .alloc_addr(branch_free),
        .issue_addr(branch_ready)
    );
    
    wire branch_rob_branch_dest_valid;
    wire branch_rob_taken;
    wire [`addrWidth - 1 : 0] branch_rob_branch_dest;
    wire [`tagWidth  - 1 : 0] branch_rob_dest;
    
    ex_branch ex_branch(
        .ex_branch_en(branch_ex_en),
        .exsrc1(branch_exsrc1),
        .exsrc2(branch_exsrc2),
        .expc(branch_expc),
        .exaluop(branch_exaluop),
        .exoffset(branch_exoffset),
        .exdest(branch_exdest),
        .branch_dest_valid(branch_rob_branch_dest_valid),
        .taken_rob(branch_rob_taken),
        .branch_dest(branch_rob_branch_dest),
        .dest_rob(branch_rob_dest)
    );
    
    wire ls_ex_en, ex_ls_done;
    wire [`dataWidth - 1 : 0] ls_exsrc1;
    wire [`dataWidth - 1 : 0] ls_exsrc2;
    wire [`dataWidth - 1 : 0] ls_exreg;
    wire [`newopWidth - 1 : 0] ls_exlsop;
    wire [`tagWidth - 1 : 0]  ls_exdest;
    wire [`rob_sel   - 1 : 0] rob_top;
    
    lsbuffer lsbuffer(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .ls_enable_1(dp_ls_enable1),
        .ls_op_1(dp_ls_op_1),
        .ls_base_1(dp_ls_base_1),
        .ls_basetag_1(dp_ls_basetag_1),
        .ls_src_1(dp_ls_src_1),
        .ls_srctag_1(dp_ls_srctag_1),
        .ls_Imm_1(dp_ls_Imm_1),
        .ls_dest_1(dp_ls_dest_1),
        .ls_enable_2(dp_ls_enable2),
        .ls_op_2(dp_ls_op_2),
        .ls_base_2(dp_ls_base_2),
        .ls_basetag_2(dp_ls_basetag_2),
        .ls_src_2(dp_ls_src_2),
        .ls_srctag_2(dp_ls_srctag_2),
        .ls_Imm_2(dp_ls_Imm_2),
        .ls_dest_2(dp_ls_dest_2),
        .en_alu_rst1(ex_alu_en1),
        .alu_rst_tag1(ex_alu_rst_tag1),
        .alu_rst_data1(ex_alu_rst_data1),
        .en_alu_rst2(ex_alu_en2),
        .alu_rst_tag2(ex_alu_rst_tag2),
        .alu_rst_data2(ex_alu_rst_data2),
        .en_mem_rst(ex_mem_en),
        .mem_rst_tag(ex_mem_rst_tag),
        .mem_rst_data(ex_mem_rst_data),
        .ex_ls_done(ex_ls_done),
        .ex_ls_en(ls_ex_en),
        .exsrc1_out(ls_exsrc1),
        .exsrc2_out(ls_exsrc2),
        .exreg_out(ls_exreg),
        .exlsop_out(ls_exlsop),
        .exdest_out(ls_exdest),
        .stall(stall),
        .lsbuffer_free(ls_free),
        .rob_top({1'b0, rob_top})
    );
    
    ex_ls ex_ls(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .ex_ls_en(ls_ex_en),
        .ex_src1(ls_exsrc1),
        .ex_src2(ls_exsrc2),
        .ex_reg(ls_exreg),
        .ex_lsop(ls_exlsop),
        .ex_dest(ls_exdest),
        .ex_ls_done(ex_ls_done),
        .en_rst(ex_mem_en),
        .rst_data(ex_mem_rst_data),
        .rst_tag(ex_mem_rst_tag),
        .rw_flag(core_mcu_rw_flag[1]),
        .addr(core_mcu_addr[1]),
        .write_data(core_mcu_data[1]),
        .len(core_mcu_len[1]),
        .read_data(mcu_core_data[1]),
        .mem_busy(mcu_core_busy[1]),
        .mem_done(mcu_core_done[1])
    );
    
    wire rob_reg_commit_en;
    wire [`reg_sel - 1 : 0] rob_reg_commit_reg;
    wire [`dataWidth - 1 : 0] rob_reg_commit_data;
    wire [`tagWidth - 1 : 0] rob_reg_commit_tag;
    
    Regfile arf(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .commit_en(rob_reg_commit_en),
        .commit_reg(rob_reg_commit_reg),
        .commit_data(rob_reg_commit_data),
        .commit_tag(rob_reg_commit_tag),
        .dp_en1(dp_reg_enable1),
        .dp_reg1(dp_reg_sel1),
        .dp_tag1(dp_reg_tag1),
        .dp_en2(dp_reg_enable2),
        .dp_reg2(dp_reg_sel2),
        .dp_tag2(dp_reg_tag2),
        .sel_1(dp_reg_regAddr1_1),
        .tag_1(reg_dp_tag1_1),
        .data_1(reg_dp_data1_1),
        .sel_2(dp_reg_regAddr2_1),
        .tag_2(reg_dp_tag2_1),
        .data_2(reg_dp_data2_1),
        .sel_3(dp_reg_regAddr1_2),
        .tag_3(reg_dp_tag1_2),
        .data_3(reg_dp_data1_2),
        .sel_4(dp_reg_regAddr2_2),
        .tag_4(reg_dp_tag2_2),
        .data_4(reg_dp_data2_2),
        .stall(stall)
    );
    
    rob reorder_buf(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .clear(clear),
        .dp_tag1_1(dp_rob_tag1_1),
        .dp_tag2_1(dp_rob_tag2_1),
        .dp_tag1_2(dp_rob_tag1_2),
        .dp_tag2_2(dp_rob_tag2_2),
        .dpw_en1(dp_rob_enable1),
        .dpw_isbranch1(dp_rob_isbranch1),
        .dpw_wrrd1(dp_rob_wr_rd1),
        .dpw_addr1(dp_rob_dest1),
        .dpw_en2(dp_rob_enable2),
        .dpw_isbranch2(dp_rob_isbranch2),
        .dpw_wrrd2(dp_rob_wr_rd2),
        .dpw_addr2(dp_rob_dest2),
        .dp_tag1_1ready(rob_dp_ready1_1),
        .dp_tag2_1ready(rob_dp_ready2_1),
        .dp_tag1_2ready(rob_dp_ready1_2),
        .dp_tag2_2ready(rob_dp_ready2_2),
        .dp_tag1_1data(rob_dp_data1_1),
        .dp_tag2_1data(rob_dp_data2_1),
        .dp_tag1_2data(rob_dp_data1_2),
        .dp_tag2_2data(rob_dp_data2_2),
        .com_wrrd(rob_reg_commit_en),
        .com_addr(rob_reg_commit_reg),
        .com_data(rob_reg_commit_data),
        .com_tag(rob_reg_commit_tag),
        .com_clear(clear),
        .com_target(rob_if_target),
        .ex_alu_en_1(ex_alu_en1),
        .ex_alu_data_1(ex_alu_rst_data1),
        .ex_alu_tag_1(ex_alu_rst_tag1),
        .ex_alu_en_2(ex_alu_en2),
        .ex_alu_data_2(ex_alu_rst_data2),
        .ex_alu_tag_2(ex_alu_rst_tag2),
        .ex_ls_en(ex_mem_en),
        .ex_ls_data(ex_mem_rst_data),
        .ex_ls_tag(ex_mem_rst_tag),
        .ex_branch_en(branch_rob_branch_dest_valid),
        .ex_branch_taken(branch_rob_taken),
        .ex_branch_tag(branch_rob_dest),
        .ex_branch_target(branch_rob_branch_dest),
        .stall(stall),
        .rob_free(rob_free),
        .alloc_ptr_1(rob_free_1),
        .alloc_ptr_2(rob_free_2),
        .com_ptr(rob_top),
        .pdt_en(rob_pdt_en),
        .pdt_choice(rob_pdt_choice)
    );

endmodule