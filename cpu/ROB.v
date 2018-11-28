`timescale 1ns/1ps

`include "defines.vh"

module ROB(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire [`tagWidth - 1 : 0] decoder_tag1,
    input wire [`tagWidth - 1 : 0] decoder_tag2,
    input wire [`tagWidth - 1 : 0] decoder_tagd,
    input wire alloc_en,
    input wire [`regWidth - 1 : 0] alloc_data,
    //output to decoder 
    output reg [`rob_sel - 1 : 0] alloc_ptr,
    output wire decoder_tag1ready,
    output wire decoder_tag2ready,
    output wire decoder_tagdready,
    output wire [`dataWidth - 1 : 0] decoder_tag1data,
    output wire [`dataWidth - 1 : 0] decoder_tag2data,
    output wire [`dataWidth - 1 : 0] decoder_tagddata,
    //output to regfile
    output wire com_en,
    output wire [`regWidth - 1 : 0] com_addr,
    output wire [`dataWidth - 1 : 0] com_data,
    output wire [`tagWidth - 1 : 0] com_tag,
    //input from ex_alu
    input wire alu_rst_en,
    input wire [`dataWidth - 1 : 0] alu_rst_data,
    input wire [`tagWidth - 1 : 0] alu_rst_tag,
    //input from ex_ls
    input wire mem_rst_en,
    input wire [`dataWidth - 1 : 0] mem_rst_data,
    input wire [`tagWidth - 1 : 0] mem_rst_tag,
    //output to PC
    output wire rob_free
);
    reg [`dataWidth - 1 : 0] data[`rob_size - 1 : 0];
    reg [`rob_size - 1 : 0]  valid;
    reg [`regWidth - 1 : 0]  dest[`rob_size - 1 : 0]; 
    reg [`rob_sel - 1 : 0] com_ptr;
    reg [`rob_sel : 0] ent_cnt;
    
    assign decoder_tag1ready = decoder_tag1 == `tagFree ? 1 : 
                               alu_rst_en && alu_rst_tag == decoder_tag1 ? 1 : 
                               mem_rst_en && mem_rst_tag == decoder_tag1 ? 1 : valid[decoder_tag1[2 : 0]];
    assign decoder_tag2ready = decoder_tag2 == `tagFree ? 1 :                              
                               alu_rst_en && alu_rst_tag == decoder_tag2 ? 1 : 
                               mem_rst_en && mem_rst_tag == decoder_tag2 ? 1 : valid[decoder_tag2[2 : 0]];
    assign decoder_tagdready = decoder_tagd == `tagFree ? 1 : 
                               alu_rst_en && alu_rst_tag == decoder_tagd ? 1 : 
                               mem_rst_en && mem_rst_tag == decoder_tagd ? 1 : valid[decoder_tagd[2 : 0]];
    assign decoder_tag1data  = alu_rst_en && alu_rst_tag == decoder_tag1 ? alu_rst_data : 
                               mem_rst_en && mem_rst_tag == decoder_tag1 ? mem_rst_data : data[decoder_tag1[2 : 0]];
    assign decoder_tag2data  = alu_rst_en && alu_rst_tag == decoder_tag2 ? alu_rst_data : 
                               mem_rst_en && mem_rst_tag == decoder_tag2 ? mem_rst_data : data[decoder_tag2[2 : 0]];
    assign decoder_tagddata  = alu_rst_en && alu_rst_tag == decoder_tagd ? alu_rst_data : 
                               mem_rst_en && mem_rst_tag == decoder_tagd ? mem_rst_data : data[decoder_tagd[2 : 0]];
    
    assign com_en   = valid[com_ptr];
    assign com_addr = dest[com_ptr];
    assign com_data = data[com_ptr];
    assign com_tag  = com_ptr;
    assign rob_free = (ent_cnt == `rob_size && !com_en) || (ent_cnt == `rob_size - 1 && alloc_en) ? 0 : 1;
                
    integer i;
    //integer counter; 
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ent_cnt <= 0;
            com_ptr  <= 0;
            alloc_ptr <= 0;
            valid <= 0;
            //counter = 0;
            for (i = 0; i < `rob_size; i = i + 1) begin
                data[i] <= 0;
                dest[i] <= `tagFree;
            end
        end else if (rdy) begin
            if (alu_rst_en) begin
                data[alu_rst_tag[2 : 0]] <= alu_rst_data;
                valid[alu_rst_tag[2 : 0]] <= 1;
            end
            if (mem_rst_en) begin
                data[mem_rst_tag[2 : 0]] <= mem_rst_data;
                valid[mem_rst_tag[2 : 0]] <= 1;
            end
            if (alloc_en && com_en) begin
                data[alloc_ptr] <= 0;
                valid[alloc_ptr] <= 0;
                valid[com_ptr] <= 0;
                dest[alloc_ptr] <= alloc_data;
                alloc_ptr <= alloc_ptr + 1;
                com_ptr <= com_ptr + 1;
                //counter = counter + 1;
            end else if (alloc_en) begin
                data[alloc_ptr] <= 0;
                valid[alloc_ptr] <= 0;
                dest[alloc_ptr] <= alloc_data;
                alloc_ptr <= alloc_ptr + 1;
                ent_cnt <= ent_cnt + 1;
            end else if (com_en) begin
                valid[com_ptr] <= 0;
                com_ptr <= com_ptr + 1;
                ent_cnt <= ent_cnt - 1;
                //counter = counter + 1;
            end
        end
    end
endmodule