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
    wire [`dataWidth - 1 : 0] mcu_core_data[1 : 0];
    wire [1 : 0]              mcu_core_busy;
    wire [1 : 0]              mcu_core_done;

    mem_ctrl mcu(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .rw_flag({core_mcu_rw_flag[1], core_mcu_rw_flag[0]}),
        .addr({core_mcu_addr[1], core_mcu_addr[0]}),
        .len({core_mcu_len[1], core_mcu_len[0]}),
        .data_in({core_mcu_data[1], core_mcu_data[0]}),
        .data_out({mcu_core_data[1], mcu_core_data[0]}),
        .busy(mcu_core_busy),
        .done(mcu_core_done),
        .ram_rw_flag(mem_wr),
        .ram_addr(mem_a),
        .ram_data_out(mem_dout),
        .ram_data_in(mem_din)        
    );
    
    wire [1 : 0]              pc_cache_rw_flag;
    wire [`addrWidth - 1 : 0] pc_cache_addr;
    wire [1 : 0]              pc_cache_len;
    wire [`dataWidth - 1 : 0] cache_pc_data;
    wire                      cache_pc_busy;
    wire                      cache_pc_done;
         
    cache cache(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .rw_flag(pc_cache_rw_flag),
        .PC(pc_cache_addr),
        .len(pc_cache_len),
        .data_out(cache_pc_data),
        .cache_busy(cache_pc_busy),
        .cache_done(cache_pc_done),
        .rw_flag_out(core_mcu_rw_flag[0]),
        .PC_out(core_mcu_addr[0]),
        .len_out(core_mcu_len[0]),
        .read_data(mcu_core_data[0]),
        .mem_busy(mcu_core_busy[0]),
        .mem_done(mcu_core_done[0])
    );  
    
    wire                      if_dec_en;
    wire [`addrWidth - 1 : 0] if_dec_pc;
    wire [`instWidth - 1 : 0] if_dec_inst;
    wire                      alu_if_jump_dest_valid;
    wire [`addrWidth - 1 : 0] alu_if_jump_dest;
    wire                      branch_if_branch_dest_valid;
    wire [`addrWidth - 1 : 0] branch_if_branch_dest;
    wire                      alu_if_alu_free;
    wire                      rob_if_rob_free;
    wire                      ls_if_ls_free;
    
    PC fetcher(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .Decoder_enable(if_dec_en),
        .PC_Decoder(if_dec_pc),
        .inst_Decoder(if_dec_inst),
        .jump_dest_valid(alu_if_jump_dest_valid),
        .jump_dest(alu_if_jump_dest),
        .branch_dest_valid(branch_if_branch_dest_valid),
        .branch_dest(branch_if_branch_dest),
        .rw_flag(pc_cache_rw_flag),
        .PC(pc_cache_addr),
        .len(pc_cache_len),
        .read_data(cache_pc_data),
        .mem_busy(cache_pc_busy),
        .mem_done(cache_pc_done),
        .alu_free(alu_if_alu_free),
        .ls_free(ls_if_ls_free),
        .rob_free(rob_if_rob_free)
    );
    
    wire                      dec_alu_en;
    wire [`aluWidth - 1 : 0]  dec_alu_data;
    wire [`addrWidth - 1 : 0] dec_alu_inst_pc;
    wire                      dec_branch_en;
    wire [`branchWidth - 1 : 0] dec_branch_data;
    wire [`addrWidth - 1 : 0] dec_branch_inst_pc;
    wire                      dec_ls_en;
    wire [`lsWidth - 1 : 0]   dec_ls_data;
    wire                      rob_dec_tag1ready;
    wire                      rob_dec_tag2ready;
    wire                      rob_dec_tagdready;
    wire [`tagWidth - 2 : 0]  rob_dec_robtail;
    wire [`dataWidth - 1 : 0] rob_dec_robdata1;
    wire [`dataWidth - 1 : 0] rob_dec_robdata2;
    wire [`dataWidth - 1 : 0] rob_dec_robdatad;
    wire                      dec_rob_en;
    wire [`regWidth - 1 : 0]  dec_rob_data;
    wire [`tagWidth - 1 : 0]  dec_rob_tagcheck1;
    wire [`tagWidth - 1 : 0]  dec_rob_tagcheck2;
    wire [`tagWidth - 1 : 0]  dec_rob_tagcheckd;
    wire [`tagWidth - 1 : 0]  arf_dec_tag1;
    wire [`tagWidth - 1 : 0]  arf_dec_tag2;
    wire [`tagWidth - 1 : 0]  arf_dec_tagd;
    wire [`dataWidth - 1 : 0] arf_dec_data1;
    wire [`dataWidth - 1 : 0] arf_dec_data2;
    wire [`dataWidth - 1 : 0] arf_dec_datad;
    wire [`regWidth - 1 : 0]  dec_arf_addr1;
    wire [`regWidth - 1 : 0]  dec_arf_addr2;
    wire [`regWidth - 1 : 0]  dec_arf_addrd;
    wire                      dec_arf_en;
    wire [`regWidth - 1 : 0]  dec_arf_tagaddr;
    wire [`tagWidth - 1 : 0]  dec_arf_tag;                       
     
    Decoder decoder(
        .decoderEnable(if_dec_en),
        .instToDecode(if_dec_inst),
        .inst_PC(if_dec_pc),
        .aluEnable(dec_alu_en),
        .aluData(dec_alu_data),
        .inst_PC_out_alu(dec_alu_inst_pc),
        .branchEnable(dec_branch_en),
        .branchData(dec_branch_data),
        .inst_PC_out_branch(dec_branch_inst_pc),
        .lsEnable(dec_ls_en),
        .lsData(dec_ls_data),
        .tag1Ready(rob_dec_tag1ready),
        .tag2Ready(rob_dec_tag2ready),
        .tagdReady(rob_dec_tagdready),
        .ROBtail(rob_dec_robtail),
        .robData1(rob_dec_robdata1),
        .robData2(rob_dec_robdata2),
        .robDatad(rob_dec_robdatad),
        .robEnable(dec_rob_en),
        .robData(dec_rob_data),
        .tagCheck1(dec_rob_tagcheck1),
        .tagCheck2(dec_rob_tagcheck2),
        .tagCheckd(dec_rob_tagcheckd),
        .regTag1(arf_dec_tag1),
        .regTag2(arf_dec_tag2),
        .regTagd(arf_dec_tagd),
        .regData1(arf_dec_data1),
        .regData2(arf_dec_data2),
        .regDatad(arf_dec_datad),
        .regAddr1(dec_arf_addr1),
        .regAddr2(dec_arf_addr2),
        .regAddrd(dec_arf_addrd),
        .regEnable(dec_arf_en),
        .regTagAddr(dec_arf_tagaddr),
        .regTag(dec_arf_tag)
    );
    
    wire ex_alu_en;
    wire [`tagWidth - 1 : 0] ex_alu_rst_tag;
    wire [`dataWidth - 1 : 0] ex_alu_rst_data;
    wire ex_mem_en;
    wire [`tagWidth - 1 : 0] ex_mem_rst_tag;
    wire [`dataWidth - 1 : 0] ex_mem_rst_data;
    
    wire alu_ex_en;
    wire [`dataWidth - 1 : 0] alu_exsrc1;
    wire [`dataWidth - 1 : 0] alu_exsrc2;
    wire [`addrWidth - 1 : 0] alu_expc;
    wire [`newopWidth - 1 : 0] alu_exaluop;
    wire [`tagWidth - 1 : 0]  alu_exdest;
    
    rs_alu rs_alu(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .alloc_enable(dec_alu_en),
        .decoder_data(dec_alu_data),
        .inst_PC(dec_alu_inst_pc),
        .en_alu_rst(ex_alu_en),
        .alu_rst_tag(ex_alu_rst_tag),
        .alu_rst_data(ex_alu_rst_data),
        .en_mem_rst(ex_mem_en),
        .mem_rst_tag(ex_mem_rst_tag),
        .mem_rst_data(ex_mem_rst_data),
        .ex_alu_en(alu_ex_en),
        .exsrc1_out(alu_exsrc1),
        .exsrc2_out(alu_exsrc2),
        .expc_out(alu_expc),
        .exaluop_out(alu_exaluop),
        .exdest_out(alu_exdest),
        .rs_alu_free(alu_if_alu_free)
    );
    
    ex_alu ex_alu(
        .ex_alu_en(alu_ex_en),
        .exsrc1(alu_exsrc1),
        .exsrc2(alu_exsrc2),
        .expc(alu_expc),
        .exaluop(alu_exaluop),
        .exdest(alu_exdest),
        .en_rst(ex_alu_en),
        .rst_data(ex_alu_rst_data),
        .rst_tag(ex_alu_rst_tag),
        .jump_dest_valid(alu_if_jump_dest_valid),
        .jump_dest(alu_if_jump_dest)
    );
    
    wire branch_ex_en;
    wire [`dataWidth - 1 : 0] branch_exsrc1;
    wire [`dataWidth - 1 : 0] branch_exsrc2;
    wire [`addrWidth - 1 : 0] branch_expc;
    wire [`newopWidth - 1 : 0] branch_exaluop;
    wire [`addrWidth - 1 : 0]  branch_exoffset;
    
    rs_branch rs_branch(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .alloc_enable(dec_branch_en),
        .decoder_data(dec_branch_data),
        .inst_PC(dec_branch_inst_pc),
        .en_alu_rst(ex_alu_en),
        .alu_rst_tag(ex_alu_rst_tag),
        .alu_rst_data(ex_alu_rst_data),
        .en_mem_rst(ex_mem_en),
        .mem_rst_tag(ex_mem_rst_tag),
        .mem_rst_data(ex_mem_rst_data),
        .ex_branch_en(branch_ex_en),
        .exsrc1_out(branch_exsrc1),
        .exsrc2_out(branch_exsrc2),
        .expc_out(branch_expc),
        .exaluop_out(branch_exaluop),
        .exoffset_out(branch_exoffset)
    );
    
    ex_branch ex_branch(
        .ex_branch_en(branch_ex_en),
        .exsrc1(branch_exsrc1),
        .exsrc2(branch_exsrc2),
        .expc(branch_expc),
        .exaluop(branch_exaluop),
        .exoffset(branch_exoffset),
        .branch_dest_valid(branch_if_branch_dest_valid),
        .branch_dest(branch_if_branch_dest)
    );
    
    wire ls_ex_en, ex_ls_done;
    wire [`dataWidth - 1 : 0] ls_exsrc1;
    wire [`dataWidth - 1 : 0] ls_exsrc2;
    wire [`dataWidth - 1 : 0] ls_exreg;
    wire [`newopWidth - 1 : 0] ls_exlsop;
    wire [`tagWidth - 1 : 0]  ls_exdest;
    
    lsbuffer lsbuffer(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .alloc_enable(dec_ls_en),
        .decoder_data(dec_ls_data),
        .en_alu_rst(ex_alu_en),
        .alu_rst_tag(ex_alu_rst_tag),
        .alu_rst_data(ex_alu_rst_data),
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
        .lsbuffer_free(ls_if_ls_free)
    );
    
    ex_ls ex_ls(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
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
    
    wire rob_arf_en;
    wire [`regWidth - 1 : 0] rob_arf_addr;
    wire [`dataWidth - 1 : 0] rob_arf_data;
    wire [`tagWidth - 1 : 0] rob_arf_tag;
    
    ROB reorder_buf(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .decoder_tag1(dec_rob_tagcheck1),
        .decoder_tag2(dec_rob_tagcheck2),
        .decoder_tagd(dec_rob_tagcheckd),
        .alloc_en(dec_rob_en),
        .alloc_data(dec_rob_data),
        .alloc_ptr(rob_dec_robtail),
        .decoder_tag1ready(rob_dec_tag1ready),
        .decoder_tag2ready(rob_dec_tag2ready),
        .decoder_tagdready(rob_dec_tagdready),
        .decoder_tag1data(rob_dec_robdata1),
        .decoder_tag2data(rob_dec_robdata2),
        .decoder_tagddata(rob_dec_robdatad),
        .com_en(rob_arf_en),
        .com_addr(rob_arf_addr),
        .com_data(rob_arf_data),
        .com_tag(rob_arf_tag),
        .alu_rst_en(ex_alu_en),
        .alu_rst_data(ex_alu_rst_data),
        .alu_rst_tag(ex_alu_rst_tag),
        .mem_rst_en(ex_mem_en),
        .mem_rst_data(ex_mem_rst_data),
        .mem_rst_tag(ex_mem_rst_tag),
        .rob_free(rob_if_rob_free)
    );
    
    Regfile arf(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .enWrite(rob_arf_en),
        .namew(rob_arf_addr),
        .dataw(rob_arf_data),
        .tagw(rob_arf_tag),
        .enDecoderw(dec_arf_en),
        .regDecoderw(dec_arf_tagaddr),
        .tagDecoderw(dec_arf_tag),
        .name1(dec_arf_addr1),
        .tag1(arf_dec_tag1),
        .data1(arf_dec_data1),
        .name2(dec_arf_addr2),
        .tag2(arf_dec_tag2),
        .data2(arf_dec_data2),
        .name3(dec_arf_addrd),
        .tag3(arf_dec_tagd),
        .data3(arf_dec_datad)
    );
endmodule