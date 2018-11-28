`timescale 1ns / 1ps

`include "defines.vh"

module allocater_issuer_alu(
    input wire [`rs_alu_size - 1 : 0] busy,
    input wire [`rs_alu_size - 1 : 0] ready,
    output reg allocate_en,
    output reg [`rs_alu_sel  - 1 : 0] allocate_addr,
    output reg issue_en,
    output reg [`rs_alu_sel  - 1 : 0] issue_addr  
);
    integer i;
    always @ (*) begin
        allocate_en = 0;
        allocate_addr = 0;
        for (i = 0; i < `rs_alu_size; i = i + 1) begin
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
        for (j = 0; j < `rs_alu_size; j = j + 1) begin
            if (ready[j]) begin
                issue_en = 1;
                issue_addr = j;
            end
        end
    end
endmodule

module source_oprand_manager(
    input wire [`tagWidth - 1 : 0] tag,
    input wire [`dataWidth - 1 : 0] data,
    input wire ex_rst1_en,
    input wire [`tagWidth - 1 : 0] ex_rst1_tag,
    input wire [`dataWidth - 1 : 0] ex_rst1_data,
    input wire ex_rst2_en,
    input wire [`tagWidth - 1 : 0] ex_rst2_tag,
    input wire [`dataWidth - 1 : 0] ex_rst2_data, 
    output wire [`dataWidth - 1 : 0] next_data,
    output wire [`tagWidth - 1 : 0] next_tag
);
    assign next_data = (ex_rst1_en && ex_rst1_tag == tag) ? ex_rst1_data : 
                       (ex_rst2_en && ex_rst2_tag == tag) ? ex_rst2_data : data;
    assign next_tag  = (ex_rst1_en && ex_rst1_tag == tag) ? `tagFree : 
                       (ex_rst2_en && ex_rst2_tag == tag) ? `tagFree : tag;
endmodule

module rs_alu_ent(
    input wire clk,
    input wire rst,
    input wire rdy,
    //allocate
    input wire busy,
    input wire allocate_en,
    input wire [`aluWidth - 1 : 0] allocate_data,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
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
    //output to rs_alu
    output wire ready 
);
    reg [`dataWidth - 1 : 0] data1, data2;
    reg [`tagWidth  - 1 : 0] tag1,  tag2;
    reg [`tagWidth  - 1 : 0] dest;
    reg [`addrWidth - 1 : 0] PC;
    reg [`newopWidth - 1 : 0] op;
    wire [`dataWidth  - 1 : 0] next_data1, next_data2;
    wire [`tagWidth   - 1 : 0] next_tag1, next_tag2;
    
    assign ex_src1 = (tag1 != `tagFree && next_tag1 == `tagFree) ? next_data1 : data1;
    assign ex_src2 = (tag2 != `tagFree && next_tag2 == `tagFree) ? next_data2 : data2; 
    assign ex_pc   = PC;
    assign ex_aluop = op;
    assign ex_dest  = dest;
    assign ready = busy && (next_tag1 == `tagFree) && (next_tag2 == `tagFree) ? 1 : 0;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            data1 <= 0;
            data2 <= 0;
            tag1  <= `tagFree;
            tag2  <= `tagFree;
            dest  <= `tagFree;
            PC    <= 0;
            op    <= `NOP;
        end else if (rdy) begin
            if (allocate_en) begin
                data1 <= allocate_data[`aluData1Range];
                tag1  <= allocate_data[`aluTag1Range];
                data2 <= allocate_data[`aluData2Range];
                tag2  <= allocate_data[`aluTag2Range];
                dest  <= allocate_data[`aluDestRange];
                PC    <= inst_PC;
                op    <= allocate_data[`aluOpRange];
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

module rs_alu(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire alloc_enable,
    input wire [`aluWidth - 1 : 0] decoder_data,
    input wire [`addrWidth - 1 : 0] inst_PC,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    //output to ex_alu
    output reg ex_alu_en,
    output reg [`dataWidth - 1 : 0] exsrc1_out,
    output reg [`dataWidth - 1 : 0] exsrc2_out,
    output reg [`addrWidth - 1 : 0] expc_out,
    output reg [`newopWidth - 1 : 0] exaluop_out,
    output reg [`tagWidth - 1 : 0] exdest_out,
    //output to PC
    output wire rs_alu_free
);
    reg [`rs_alu_size - 1 : 0] busy;
    reg [`rs_alu_sel : 0] ent_counter;
    wire [`rs_alu_size - 1 : 0] ready;
    wire allocate_en, issue_en;
    wire [`rs_alu_sel - 1 : 0] allocate_addr, issue_addr;
    wire [`dataWidth - 1 : 0] exsrc1[`rs_alu_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2[`rs_alu_size - 1 : 0];
    wire [`addrWidth - 1 : 0] expc  [`rs_alu_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exaluop [`rs_alu_size - 1 : 0];
    wire [`tagWidth   - 1 : 0] exdest [`rs_alu_size - 1 : 0];
    
    assign rs_alu_free = (ent_counter == `rs_alu_size && !issue_en) || (ent_counter == `rs_alu_size - 1 && alloc_enable) ? 0 : 1;
    
    allocater_issuer_alu aoko_alu(
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
            ent_counter <= 0;
        end else if (rdy) begin
            if (alloc_enable && allocate_en && issue_en) begin 
                busy[allocate_addr] <= 1'b1;
                busy[issue_addr]    <= 1'b0;
            end else if (alloc_enable && allocate_en) begin
                busy[allocate_addr] <= 1'b1;
                ent_counter <= ent_counter + 1;
            end else if (issue_en) begin
                busy[issue_addr]    <= 1'b0;
                ent_counter <= ent_counter - 1;
            end
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
                .ex_dest(exdest[i]),
                .ready(ready[i])
            );
        end
    endgenerate
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ex_alu_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            expc_out <= 0;
            exaluop_out <= 0;
            exdest_out <= 0;
        end else if (rdy) begin
            ex_alu_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            expc_out <= 0;
            exaluop_out <= 0;
            exdest_out <= 0;
            if (issue_en) begin
                ex_alu_en <= 1;
                exsrc1_out <= exsrc1[issue_addr];
                exsrc2_out <= exsrc2[issue_addr];
                expc_out   <= expc  [issue_addr];
                exaluop_out <= exaluop[issue_addr];
                exdest_out <= exdest[issue_addr];
            end
        end
    end
endmodule
