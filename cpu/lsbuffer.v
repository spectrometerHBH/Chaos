`timescale 1ns / 1ps

`include "defines.vh"

module lsbuffer_ent(
    input wire clk,
    input wire rst,
    input wire rdy,
    //allocate
    input wire busy,
    input wire allocate_en,
    input wire [`lsWidth - 1 : 0] allocate_data,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    //output to ex_ls
    output wire [`dataWidth - 1 : 0] ex_src1,
    output wire [`dataWidth - 1 : 0] ex_src2,
    output wire [`dataWidth - 1 : 0] ex_reg,
    output wire [`newopWidth - 1 : 0] ex_lsop,
    output wire [`tagWidth  - 1 : 0] ex_dest,
    //output to rs_ls
    output wire ready 
);
    reg [`dataWidth - 1 : 0] data1, data2, Imm;
    reg [`tagWidth  - 1 : 0] tag1,  tag2;
    reg [`tagWidth  - 1 : 0] dest;
    reg [`newopWidth - 1 : 0] op;
    wire [`dataWidth  - 1 : 0] next_data1, next_data2;
    wire [`tagWidth   - 1 : 0] next_tag1, next_tag2;
    
    assign ex_src1 = (tag1 != `tagFree && next_tag1 == `tagFree) ? next_data1 : data1;
    assign ex_src2 = Imm;
    assign ex_reg  = (tag2 != `tagFree && next_tag2 == `tagFree) ? next_data2 : data2; 
    assign ex_lsop = op;
    assign ex_dest  = dest;
    assign ready = busy && (next_tag1 == `tagFree) && (next_tag2 == `tagFree) ? 1 : 0;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            data1 <= 0;
            data2 <= 0;
            Imm   <= 0;
            tag1  <= `tagFree;
            tag2  <= `tagFree;
            dest  <= `tagFree;
            op    <= `NOP;
        end else if (rdy) begin
            if (allocate_en) begin
                data1 <= allocate_data[`lsBaseRange];
                tag1  <= allocate_data[`lsBaseTagRange];
                data2 <= allocate_data[`lsSrcRange];
                tag2  <= allocate_data[`lsSrcTagRange];
                dest  <= allocate_data[`lsDestRange];
                Imm   <= allocate_data[`lsImmRange];
                op    <= allocate_data[`lsOpRange];
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

module lsbuffer(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire alloc_enable,
    input wire [`lsWidth - 1 : 0] decoder_data,
    //input from ex_alu
    input wire en_alu_rst,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    //input from ex_ls
    input wire en_mem_rst,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    input wire ex_ls_done,
    //output to ex_ls
    output reg ex_ls_en,
    output reg [`dataWidth - 1 : 0] exsrc1_out,
    output reg [`dataWidth - 1 : 0] exsrc2_out,
    output reg [`dataWidth - 1 : 0] exreg_out,
    output reg [`newopWidth - 1 : 0] exlsop_out,
    output reg [`tagWidth - 1 : 0] exdest_out,
    //output to PC
    output wire lsbuffer_free
);
    reg  [`lsbuf_size - 1 : 0] busy;
    wire [`lsbuf_size - 1 : 0] ready;
    reg  [`lsbuf_sel - 1 : 0] allocate_addr, issue_addr;
    reg  [`lsbuf_sel     : 0] ent_cnt; 
    wire [`dataWidth - 1 : 0] exsrc1[`lsbuf_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2[`lsbuf_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exreg  [`lsbuf_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exlsop [`lsbuf_size - 1 : 0];
    wire [`tagWidth   - 1 : 0] exdest [`lsbuf_size - 1 : 0];
    wire issue_en;
    
    assign lsbuffer_free = (ent_cnt == `lsbuf_size && !issue_en) || (ent_cnt == `lsbuf_size - 1 && alloc_enable) ? 0 : 1;
    assign issue_en      = ready[issue_addr] && ex_ls_done;
     
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            busy          <= 0;
            allocate_addr <= 0;
            issue_addr    <= 0;
            ent_cnt       <= 0;
        end else if (rdy) begin
            if (alloc_enable && issue_en) begin
                busy[allocate_addr] <= 1;
                busy[issue_addr]    <= 0;
                allocate_addr <= allocate_addr + 1;
                issue_addr <= issue_addr + 1;
            end else if (alloc_enable) begin
                busy[allocate_addr] <= 1;
                allocate_addr <= allocate_addr + 1;
                ent_cnt <= ent_cnt + 1;
            end else if (issue_en) begin
                busy[issue_addr] <= 0;
                issue_addr <= issue_addr + 1;
                ent_cnt <= ent_cnt - 1;
            end
        end
    end
    
    generate
        genvar i;
        for (i = 0; i < `lsbuf_size; i = i + 1) begin : lsbuffer
            lsbuffer_ent lsbuffer_ent(
                .clk(clk),
                .rst(rst),
                .rdy(rdy),
                .busy(busy[i]),
                .allocate_en(alloc_enable && allocate_addr == i),
                .allocate_data(decoder_data),
                .en_alu_rst(en_alu_rst),
                .alu_rst_tag(alu_rst_tag),
                .alu_rst_data(alu_rst_data),
                .en_mem_rst(en_mem_rst),
                .mem_rst_tag(mem_rst_tag),
                .mem_rst_data(mem_rst_data),
                .ex_src1(exsrc1[i]),
                .ex_src2(exsrc2[i]),
                .ex_reg(exreg[i]),
                .ex_lsop(exlsop[i]),
                .ex_dest(exdest[i]),
                .ready(ready[i])
            );
        end
    endgenerate
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ex_ls_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            exreg_out <= 0;
            exlsop_out <= 0;
            exdest_out <= 0;
        end else if (rdy) begin
            ex_ls_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            exreg_out <= 0;
            exlsop_out <= 0;
            exdest_out <= 0;
            if (issue_en) begin
                ex_ls_en <= 1;
                exsrc1_out <= exsrc1[issue_addr];
                exsrc2_out <= exsrc2[issue_addr];
                exreg_out  <= exreg [issue_addr];
                exlsop_out <= exlsop[issue_addr];
                exdest_out <= exdest[issue_addr];
            end
        end
    end
endmodule
