`timescale 1ns / 1ps

`include "defines.vh"

module allocater_issuer_branch(
    input wire [`rs_branch_size - 1 : 0] busy,
    input wire [`rs_branch_size - 1 : 0] ready,
    output reg allocate_en,
    output reg [`rs_branch_sel  - 1 : 0] allocate_addr,
    output reg issue_en,
    output reg [`rs_branch_sel  - 1 : 0] issue_addr  
);
    integer i;
    always @ (*) begin
        allocate_en = 0;
        allocate_addr = 0;
        for (i = 0; i < `rs_branch_size; i = i + 1) begin
            if (!busy[i]) begin
                allocate_en = 1;
                allocate_addr = i;
            end
        end
    end
    
    integer j;
    always @ (*) begin
        issue_en = 0;
        issue_addr = 0;
        for (j = 0; j < `rs_branch_size; j = j + 1) begin
            if (ready[j]) begin
                issue_en = 1;
                issue_addr = j;
            end
        end
    end
endmodule

module rs_branch_ent(
    input wire clk,
    input wire rst,
    input wire rdy,
    //allocate
    input wire busy,
    input wire allocate_en,
    input wire [`branchWidth - 1 : 0] allocate_data,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    //output to ex_branch
    output wire [`dataWidth - 1 : 0] ex_src1,
    output wire [`dataWidth - 1 : 0] ex_src2,
    output wire [`addrWidth - 1 : 0] ex_pc,
    output wire [`newopWidth - 1 : 0] ex_aluop,
    output wire [`dataWidth  - 1 : 0] ex_offset,
    //output to rs_branch
    output wire ready
);
    reg [`dataWidth - 1 : 0] data1, data2;
    reg [`tagWidth  - 1 : 0] tag1, tag2;
    reg [`dataWidth - 1 : 0] offset;
    reg [`addrWidth - 1 : 0] PC;
    reg [`newopWidth - 1 : 0] op;
    wire [`dataWidth - 1 : 0] next_data1, next_data2;
    wire [`tagWidth - 1 : 0] next_tag1, next_tag2;
    
    assign ex_src1 = (tag1 != `tagFree && next_tag1 == `tagFree) ? next_data1 : data1;
    assign ex_src2 = (tag2 != `tagFree && next_tag2 == `tagFree) ? next_data2 : data2;
    assign ex_pc   = PC;
    assign ex_aluop = op;
    assign ex_offset = offset;
    assign ready = busy && (next_tag1 == `tagFree) && (next_tag2 == `tagFree) ? 1 : 0;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            data1 <= 0;
            data2 <= 0;
            tag1  <= `tagFree;
            tag2  <= `tagFree;
            offset <= 0;
            PC    <= 0;
            op    <= `NOP;
        end else if (rdy) begin
            if (allocate_en) begin
                data1 <= allocate_data[`branchData1Range];
                tag1  <= allocate_data[`branchTag1Range];
                data2 <= allocate_data[`branchData2Range];
                tag2  <= allocate_data[`branchTag2Range];
                offset <= allocate_data[`branchOffsetRange];
                PC    <= inst_PC;
                op    <= allocate_data[`branchOpRange];
            end else begin
                data1 <= next_data1;
                tag1  <= next_tag1;
                data2 <= next_data2;
                tag2  <= next_tag2;
            end
        end
    end
    
    source_oprand_manager som1(
        .tag(tag1),
        .data(data1),
        .ex_rst1_en(en_alu_rst),
        .ex_rst1_tag(alu_rst_tag),
        .ex_rst1_data(alu_rst_data),
        .ex_rst2_en(en_mem_rst),
        .ex_rst2_tag(mem_rst_tag),
        .ex_rst2_data(mem_rst_data),
        .next_data(next_data1),
        .next_tag(next_tag1)
    );
    
    source_oprand_manager som2(
        .tag(tag2),
        .data(data2),
        .ex_rst1_en(en_alu_rst),
        .ex_rst1_tag(alu_rst_tag),
        .ex_rst1_data(alu_rst_data),
        .ex_rst2_en(en_mem_rst),
        .ex_rst2_tag(mem_rst_tag),
        .ex_rst2_data(mem_rst_data),
        .next_data(next_data2),
        .next_tag(next_tag2)
    );
endmodule

module rs_branch(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from Decoder
    input alloc_enable,
    input wire [`branchWidth - 1 : 0] decoder_data,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    //output to ex_branch
    output reg ex_branch_en,
    output reg [`dataWidth - 1 : 0] exsrc1_out,
    output reg [`dataWidth - 1 : 0] exsrc2_out,
    output reg [`addrWidth - 1 : 0] expc_out,
    output reg [`newopWidth - 1 : 0] exaluop_out,
    output reg [`dataWidth - 1 : 0] exoffset_out
);
    reg [`rs_branch_size - 1 : 0] busy;
    wire [`rs_branch_size - 1 : 0] ready;
    wire allocate_en, issue_en;
    wire [`rs_branch_sel - 1 : 0] allocate_addr, issue_addr;
    wire [`dataWidth - 1 : 0] exsrc1[`rs_branch_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2[`rs_branch_size - 1 : 0];
    wire [`addrWidth - 1 : 0] expc  [`rs_branch_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exoffset[`rs_branch_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exaluop[`rs_branch_size - 1 : 0];
    
    allocater_issuer_branch aoko_branch(
        .busy(busy),
        .ready(ready),
        .allocate_en(allocate_en),
        .allocate_addr(allocate_addr),
        .issue_en(issue_en),
        .issue_addr(issue_addr)
    );
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 0;
        end else if (rdy) begin
            if (alloc_enable && allocate_en) busy[allocate_addr] <= 1'b1;
            if (issue_en)                    busy[issue_addr]    <= 1'b0;
        end
    end
    
    generate
        genvar i;
        for (i = 0; i < `rs_branch_size; i = i + 1) begin : rs_branch
            rs_branch_ent rs_branch_ent(
                .clk(clk),
                .rst(rst),
                .rdy(rdy),
                .busy(busy[i]),
                .allocate_en(alloc_enable && allocate_en && allocate_addr == i),
                .allocate_data(decoder_data),
                .inst_PC(inst_PC),
                .en_alu_rst(en_alu_rst),
                .alu_rst_tag(alu_rst_tag),
                .alu_rst_data(alu_rst_data),
                .en_mem_rst(en_mem_rst),
                .mem_rst_tag(mem_rst_tag),
                .mem_rst_data(mem_rst_data),
                .ex_src1(exsrc1[i]),
                .ex_src2(exsrc2[i]),
                .ex_pc(expc[i]),
                .ex_aluop(exaluop[i]),
                .ex_offset(exoffset[i]),
                .ready(ready[i])
            );
        end    
    endgenerate
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ex_branch_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            expc_out <= 0;
            exaluop_out <= 0;
            exoffset_out <= 0; 
        end else if (rdy) begin
            ex_branch_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            expc_out <= 0;
            exaluop_out <= 0;
            exoffset_out <= 0; 
            if (issue_en) begin
                ex_branch_en <= 1;
                exsrc1_out <= exsrc1[issue_addr];
                exsrc2_out <= exsrc2[issue_addr];
                expc_out <= expc    [issue_addr];
                exaluop_out <= exaluop[issue_addr];
                exoffset_out <= exoffset[issue_addr]; 
            end
        end
    end
endmodule
