`timescale 1ns / 1ps

`include "defines.vh"

module source_oprand_manager(
    input wire [`tagWidth - 1 : 0] tag,
    input wire [`dataWidth - 1 : 0] data,
    input wire ex_rst1_en,
    input wire [`tagWidth - 1 : 0] ex_rst1_tag,
    input wire [`dataWidth - 1 : 0] ex_rst1_data,
    input wire ex_rst2_en,
    input wire [`tagWidth - 1 : 0] ex_rst2_tag,
    input wire [`dataWidth - 1 : 0] ex_rst2_data, 
    input wire ex_rst3_en,
    input wire [`tagWidth - 1 : 0] ex_rst3_tag,
    input wire [`dataWidth - 1 : 0] ex_rst3_data,
    output wire [`dataWidth - 1 : 0] next_data,
    output wire [`tagWidth - 1 : 0] next_tag
);
    assign next_data = (ex_rst1_en && ex_rst1_tag == tag) ? ex_rst1_data : 
                       (ex_rst2_en && ex_rst2_tag == tag) ? ex_rst2_data : 
                       (ex_rst3_en && ex_rst3_tag == tag) ? ex_rst3_data : data;
    assign next_tag  = (ex_rst1_en && ex_rst1_tag == tag) ? `tagFree : 
                       (ex_rst2_en && ex_rst2_tag == tag) ? `tagFree : 
                       (ex_rst3_en && ex_rst3_tag == tag) ? `tagFree : tag;
endmodule

module rs_alu_ent(
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
    input wire [`tagWidth   - 1 : 0] dest_i,
    input wire [`reg_sel    - 1 : 0] reg_i,
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
    //output to ex_alu
    output wire [`dataWidth - 1 : 0] ex_src1,
    output wire [`dataWidth - 1 : 0] ex_src2,
    output wire [`addrWidth - 1 : 0] ex_pc,
    output wire [`newopWidth - 1 : 0] ex_aluop,
    output wire [`tagWidth  - 1 : 0] ex_dest,
    output wire [`reg_sel   - 1 : 0] ex_reg,
    //output to rs_alu
    output wire ready 
);
    reg [`dataWidth - 1 : 0] data1, data2;
    reg [`tagWidth  - 1 : 0] tag1,  tag2;
    reg [`tagWidth  - 1 : 0] dest;
    reg [`addrWidth - 1 : 0] PC;
    reg [`newopWidth - 1 : 0] op;
    reg [`reg_sel   - 1 : 0] dreg;
    wire [`dataWidth  - 1 : 0] next_data1, next_data2;
    wire [`tagWidth   - 1 : 0] next_tag1, next_tag2;
    
    assign ex_src1 = (tag1 != `tagFree && next_tag1 == `tagFree) ? next_data1 : data1;
    assign ex_src2 = (tag2 != `tagFree && next_tag2 == `tagFree) ? next_data2 : data2; 
    assign ex_pc   = PC;
    assign ex_aluop = op;
    assign ex_dest  = dest;
    assign ex_reg = dreg;
    assign ready = busy && (next_tag1 == `tagFree) && (next_tag2 == `tagFree) ? 0 : 1;
    
    always @ (posedge clk) begin
        if (rst) begin
            data1 <= 0;
            data2 <= 0;
            tag1  <= `tagFree;
            tag2  <= `tagFree;
            dest  <= `tagFree;
            PC    <= 0;
            op    <= `NOP;
            dreg  <= 0;
        end else if (rdy) begin
            if (allocate_en) begin
                data1 <= data1_i;
                tag1  <= tag1_i;
                data2 <= data2_i;
                tag2  <= tag2_i;
                dest  <= dest_i;
                PC    <= PC_i;
                op    <= op_i;
                dreg  <= reg_i;
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

module rs_alu(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire alu_enable_1,
    input wire [`newopWidth - 1 : 0] alu_op_1,
    input wire [`dataWidth  - 1 : 0] alu_data1_1,
    input wire [`tagWidth   - 1 : 0] alu_tag1_1,
    input wire [`dataWidth  - 1 : 0] alu_data2_1,
    input wire [`tagWidth   - 1 : 0] alu_tag2_1,
    input wire[`addrWidth  - 1 : 0] alu_PC_1,
    input wire [`tagWidth   - 1 : 0] alu_dest_1,
    input wire [`reg_sel    - 1 : 0] alu_reg_1,
    input wire alu_enable_2,
    input wire [`newopWidth - 1 : 0] alu_op_2,
    input wire [`dataWidth  - 1 : 0] alu_data1_2,
    input wire [`tagWidth   - 1 : 0] alu_tag1_2,
    input wire [`dataWidth  - 1 : 0] alu_data2_2,
    input wire [`tagWidth   - 1 : 0] alu_tag2_2,
    input wire[`addrWidth  - 1 : 0] alu_PC_2,
    input wire [`tagWidth   - 1 : 0] alu_dest_2,
    input wire [`reg_sel    - 1 : 0] alu_reg_2,
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
    //output to ex_alu
    output reg ex_alu_en1,
    output reg [`dataWidth - 1 : 0] exsrc1_out1,
    output reg [`dataWidth - 1 : 0] exsrc2_out1,
    output reg [`addrWidth - 1 : 0] expc_out1,
    output reg [`newopWidth - 1 : 0] exaluop_out1,
    output reg [`tagWidth - 1 : 0] exdest_out1,
    output reg [`reg_sel  - 1 : 0] exreg_out1,
    output reg ex_alu_en2,
    output reg [`dataWidth - 1 : 0] exsrc1_out2,
    output reg [`dataWidth - 1 : 0] exsrc2_out2,
    output reg [`addrWidth - 1 : 0] expc_out2,
    output reg [`newopWidth - 1 : 0] exaluop_out2,
    output reg [`tagWidth - 1 : 0] exdest_out2,
    output reg [`reg_sel  - 1 : 0] exreg_out2,
    //status
    output wire rs_alu_free,
    output reg [`rs_alu_size - 1 : 0] busy,
    output wire [`rs_alu_size - 1 : 0] ready,
    input wire stall,
    input wire [`rs_alu_sel - 1 : 0] alloc_addr_1,
    input wire [`rs_alu_sel - 1 : 0] alloc_addr_2,
    input wire [`rs_alu_sel - 1 : 0] issue_addr_1,
    input wire [`rs_alu_sel - 1 : 0] issue_addr_2
);
    reg [`rs_alu_sel : 0] ent_counter;
    wire issue_en_1, issue_en_2;
    wire [`dataWidth - 1 : 0] exsrc1[`rs_alu_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2[`rs_alu_size - 1 : 0];
    wire [`addrWidth - 1 : 0] expc  [`rs_alu_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exaluop [`rs_alu_size - 1 : 0];
    wire [`tagWidth   - 1 : 0] exdest [`rs_alu_size - 1 : 0];
    wire [`reg_sel    - 1 : 0] exreg  [`rs_alu_size - 1 : 0];
    
    reg                       alloc_en[`rs_alu_size - 1 : 0];
    reg  [`dataWidth - 1 : 0] alloc_data1[`rs_alu_size - 1 : 0];
    reg  [`dataWidth - 1 : 0] alloc_data2[`rs_alu_size - 1 : 0]; 
    reg  [`tagWidth  - 1 : 0] alloc_tag1[`rs_alu_size - 1 : 0];
    reg  [`tagWidth  - 1 : 0] alloc_tag2[`rs_alu_size - 1 : 0];
    reg  [`addrWidth - 1 : 0] alloc_pc[`rs_alu_size - 1 : 0];
    reg  [`newopWidth - 1 : 0] alloc_op[`rs_alu_size - 1 : 0];
    reg  [`tagWidth  - 1 : 0] alloc_dest[`rs_alu_size - 1 : 0];
    reg  [`reg_sel   - 1 : 0] alloc_reg[`rs_alu_size - 1 : 0];
    
    assign issue_en_1 = issue_addr_1 != 3'b111 ? 1 : 0;
    assign issue_en_2 = issue_addr_2 != 3'b111 ? 1 : 0;
    assign rs_alu_free = (alu_enable_1 && alloc_addr_1 == 3'b111) || (alu_enable_2 && alloc_addr_2 == 3'b111) ? 0 : 1;
    
    always @ (posedge clk) begin
        if (rst) begin
            busy <= 0;
        end else if (rdy) begin
            if (alu_enable_1 && !stall) busy[alloc_addr_1] <= 1;
            if (alu_enable_2 && !stall) busy[alloc_addr_2] <= 1;
            if (issue_en_1) busy[issue_addr_1] <= 0;
            if (issue_en_2) busy[issue_addr_2] <= 0; 
        end
    end
    
    generate
        genvar i;
        for (i = 0; i < `rs_alu_size; i = i + 1) begin : rs_alu
            rs_alu_ent rs_alu_ent(
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
                .dest_i(alloc_dest[i]),
                .reg_i(alloc_reg[i]),
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
                .ex_dest(exdest[i]),
                .ex_reg(exreg[i]),
                .ready(ready[i])
            );
        end
    endgenerate
    
    integer k;
    always @ (*) begin
        for (k = 0; k < `rs_alu_size; k = k + 1) begin
            alloc_en[k] = 0;
            alloc_data1[k] = 0;
            alloc_data2[k] = 0;
            alloc_tag1[k] = `tagFree;
            alloc_tag2[k] = `tagFree;
            alloc_pc[k] = 0;
            alloc_op[k] = `NOP;
            alloc_dest[k] = `tagFree;
            alloc_reg[k] = 0;
        end
        if (alu_enable_1 && !stall) begin
            alloc_en[alloc_addr_1] = 1;
            alloc_data1[alloc_addr_1] = alu_data1_1;
            alloc_data2[alloc_addr_1] = alu_data2_1;
            alloc_tag1[alloc_addr_1] = alu_tag1_1;
            alloc_tag2[alloc_addr_1] = alu_tag2_1;
            alloc_pc[alloc_addr_1] = alu_PC_1;
            alloc_op[alloc_addr_1] = alu_op_1;
            alloc_dest[alloc_addr_1] = alu_dest_1;
            alloc_reg[alloc_addr_1] = alu_reg_1;
        end
        if (alu_enable_2 && !stall) begin
            alloc_en[alloc_addr_2] = 1;
            alloc_data1[alloc_addr_2] = alu_data1_2;
            alloc_data2[alloc_addr_2] = alu_data2_2;
            alloc_tag1[alloc_addr_2] = alu_tag1_2;
            alloc_tag2[alloc_addr_2] = alu_tag2_2;
            alloc_pc[alloc_addr_2] = alu_PC_2;
            alloc_op[alloc_addr_2] = alu_op_2;
            alloc_dest[alloc_addr_2] = alu_dest_2;
            alloc_reg[alloc_addr_2] = alu_reg_2;
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            ex_alu_en1 <= 0;
            exsrc1_out1 <= 0;
            exsrc2_out1 <= 0;
            expc_out1 <= 0;
            exaluop_out1 <= 0;
            exdest_out1 <= `tagFree;
            exreg_out1 <= 0;
            ex_alu_en2 <= 0;
            exsrc1_out2 <= 0;
            exsrc2_out2 <= 0;
            expc_out2 <= 0;
            exaluop_out2 <= 0;
            exdest_out2 <= `tagFree;
            exreg_out2 <= 0;
        end else if (rdy) begin
            ex_alu_en1 <= 0;
            exsrc1_out1 <= 0;
            exsrc2_out1 <= 0;
            expc_out1 <= 0;
            exaluop_out1 <= 0;
            exdest_out1 <= `tagFree;
            exreg_out1 <= 0;
            ex_alu_en2 <= 0;
            exsrc1_out2 <= 0;
            exsrc2_out2 <= 0;
            expc_out2 <= 0;
            exaluop_out2 <= `tagFree;
            exdest_out2 <= 0;
            exreg_out2 <= 0;
            if (issue_en_1) begin
                ex_alu_en1 <= 1;
                exsrc1_out1 <= exsrc1[issue_addr_1];
                exsrc2_out1 <= exsrc2[issue_addr_1];
                expc_out1   <= expc  [issue_addr_1];
                exaluop_out1 <= exaluop[issue_addr_1];
                exdest_out1 <= exdest[issue_addr_1];
                exreg_out1 <= exreg[issue_addr_1];
            end
            if (issue_en_2) begin
                ex_alu_en2 <= 1;
                exsrc1_out2 <= exsrc1[issue_addr_2];
                exsrc2_out2 <= exsrc2[issue_addr_2];
                expc_out2   <= expc  [issue_addr_2];
                exaluop_out2 <= exaluop[issue_addr_2];
                exdest_out2 <= exdest[issue_addr_2];
                exreg_out2 <= exreg[issue_addr_2];
            end
        end
    end
endmodule
