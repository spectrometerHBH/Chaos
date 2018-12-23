`timescale 1ns / 1ps

`include "defines.vh"

module rs_branch_ent(
    input wire clk,
    input wire rst,
    input wire rdy,
    //allocate
    input wire busy,
    input wire allocate_en,
    input wire [`newopWidth - 1 : 0] op_i,
    input wire [`dataWidth  - 1 : 0] data1_i,
    input wire [`tagWidth   - 1 : 0] tag1_i,
    input wire [`dataWidth  - 1 : 0] data2_i,
    input wire [`tagWidth   - 1 : 0] tag2_i,
    input wire [`addrWidth  - 1 : 0] PC_i,
    input wire [`addrWidth  - 1 : 0] offset_i,
    //input from ex_alu
    input wire en_alu_rst1,
    input wire [`tagWidth - 1 : 0] alu_rst_tag1,
    input wire [`dataWidth - 1 : 0] alu_rst_data1,
    input wire en_alu_rst2,
    input wire [`tagWidth - 1 : 0] alu_rst_tag2,
    input wire [`dataWidth - 1 : 0] alu_rst_data2,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    //output to ex_branch
    output wire [`dataWidth - 1 : 0] ex_src1,
    output wire [`dataWidth - 1 : 0] ex_src2,
    output wire [`addrWidth - 1 : 0] ex_pc,
    output wire [`newopWidth - 1 : 0] ex_aluop,
    output wire [`addrWidth  - 1 : 0] ex_offset,
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
    
    always @ (posedge clk) begin
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
                data1 <= data1_i;
                tag1  <= tag1_i;
                data2 <= data2_i;
                tag2  <= tag2_i;
                offset <= offset_i;
                PC    <= PC_i;
                op    <= op_i;
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
        .ex_rst1_en(en_alu_rst1),
        .ex_rst1_tag(alu_rst_tag1),
        .ex_rst1_data(alu_rst_data1),
        .ex_rst2_en(en_mem_rst),
        .ex_rst2_tag(mem_rst_tag),
        .ex_rst2_data(mem_rst_data),
        .ex_rst3_en(en_alu_rst2),
        .ex_rst3_tag(alu_rst_tag2),
        .ex_rst3_data(alu_rst_data2),
        .next_data(next_data1),
        .next_tag(next_tag1)
    );
    
    source_oprand_manager som2(
        .tag(tag2),
        .data(data2),
        .ex_rst1_en(en_alu_rst1),
        .ex_rst1_tag(alu_rst_tag1),
        .ex_rst1_data(alu_rst_data1),
        .ex_rst2_en(en_mem_rst),
        .ex_rst2_tag(mem_rst_tag),
        .ex_rst2_data(mem_rst_data),
        .ex_rst3_en(en_alu_rst2),
        .ex_rst3_tag(alu_rst_tag2),
        .ex_rst3_data(alu_rst_data2),
        .next_data(next_data2),
        .next_tag(next_tag2)
    );
endmodule

module rs_branch(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire branch_enable,
    input wire [`newopWidth - 1 : 0] branch_op,
    input wire [`dataWidth  - 1 : 0] branch_data1,
    input wire [`tagWidth   - 1 : 0] branch_tag1,
    input wire [`dataWidth  - 1 : 0] branch_data2,
    input wire [`tagWidth   - 1 : 0] branch_tag2,
    input wire [`addrWidth  - 1 : 0] branch_PC,
    input wire [`addrWidth  - 1 : 0] branch_offset,
    //input from ex_alu
    input wire en_alu_rst1,
    input wire [`tagWidth - 1 : 0] alu_rst_tag1,
    input wire [`dataWidth - 1 : 0] alu_rst_data1,
    input wire en_alu_rst2,
    input wire [`tagWidth - 1 : 0] alu_rst_tag2,
    input wire [`dataWidth - 1 : 0] alu_rst_data2,
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
    output reg [`dataWidth - 1 : 0] exoffset_out,
    //stall
    input wire stall
);
    reg  [`rs_branch_size - 1 : 0] busy;
    wire [`rs_branch_size - 1 : 0] ready;
    wire [`dataWidth - 1 : 0] exsrc1[`rs_branch_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2[`rs_branch_size - 1 : 0];
    wire [`addrWidth - 1 : 0] expc  [`rs_branch_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exoffset[`rs_branch_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exaluop[`rs_branch_size - 1 : 0];
    
    reg                       alloc_en[`rs_branch_size - 1 : 0];
    reg  [`dataWidth - 1 : 0] alloc_data1[`rs_branch_size - 1 : 0];
    reg  [`dataWidth - 1 : 0] alloc_data2[`rs_branch_size - 1 : 0]; 
    reg  [`tagWidth  - 1 : 0] alloc_tag1[`rs_branch_size - 1 : 0];
    reg  [`tagWidth  - 1 : 0] alloc_tag2[`rs_branch_size - 1 : 0];
    reg  [`addrWidth - 1 : 0] alloc_pc[`rs_branch_size - 1 : 0];
    reg  [`newopWidth - 1 : 0] alloc_op[`rs_branch_size - 1 : 0];
    reg  [`addrWidth  - 1 : 0] alloc_offset[`rs_branch_size - 1 : 0];
    
    always @ (posedge clk) begin
        if (rst) begin
            busy <= 0;
        end else if (rdy) begin
            if (branch_enable && !stall) busy[0] <= 1'b1;
            if (ready[0])                busy[0] <= 1'b0;
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
                .allocate_en(alloc_en[i]),
                .op_i(alloc_op[i]),
                .data1_i(alloc_data1[i]),
                .tag1_i(alloc_tag1[i]),
                .data2_i(alloc_data2[i]),
                .tag2_i(alloc_tag2[i]),
                .PC_i(alloc_pc[i]),
                .offset_i(alloc_offset[i]),
                .en_alu_rst1(en_alu_rst1),
                .alu_rst_tag1(alu_rst_tag1),
                .alu_rst_data1(alu_rst_data1),
                .en_alu_rst2(en_alu_rst2),
                .alu_rst_tag2(alu_rst_tag2),
                .alu_rst_data2(alu_rst_data2),
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
    
    integer k;
    always @ (*) begin
        for (k = 0; k < `rs_branch_size; k = k + 1) begin
            alloc_en[k] = 0;
            alloc_data1[k] = 0;
            alloc_data2[k] = 0;
            alloc_tag1[k] = `tagFree;
            alloc_tag2[k] = `tagFree;
            alloc_pc[k] = 0;
            alloc_op[k] = `NOP;
            alloc_offset[k] = 0;
            if (branch_enable && !stall) begin
                alloc_en[k] = 1;
                alloc_data1[k] = branch_data1;
                alloc_data2[k] = branch_data2;
                alloc_tag1[k] = branch_tag1;
                alloc_tag2[k] = branch_tag2;
                alloc_pc[k] = branch_PC;
                alloc_op[k] = branch_op;
                alloc_offset[k] = branch_offset;
            end
        end
    end
    
    always @ (posedge clk) begin
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
            if (ready[0]) begin
                ex_branch_en <= 1;
                exsrc1_out <= exsrc1[0];
                exsrc2_out <= exsrc2[0];
                expc_out <= expc    [0];
                exaluop_out <= exaluop[0];
                exoffset_out <= exoffset[0]; 
            end
        end
    end
endmodule
