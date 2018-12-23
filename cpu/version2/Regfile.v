`timescale 1ns/1ps

`include "defines.vh"

module Regfile(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear,
    //Write Port with ROB
    input wire commit_en,
    input wire [`reg_sel - 1 : 0] commit_reg,
    input wire [`dataWidth - 1 : 0] commit_data,
    input wire [`tagWidth - 1 : 0] commit_tag,
    //Write Port with Dispatcher
    input wire dp_en1,
    input wire [`reg_sel - 1 : 0] dp_reg1,
    input wire [`tagWidth - 1 : 0] dp_tag1,
    input wire dp_en2,
    input wire [`reg_sel - 1 : 0] dp_reg2,
    input wire [`tagWidth - 1 : 0] dp_tag2,
    //Read Port1
    input wire [`reg_sel - 1 : 0] sel_1,
    output reg [`tagWidth  - 1 : 0] tag_1,
    output reg [`dataWidth - 1 : 0] data_1,
    //Read Port2
    input wire [`reg_sel - 1 : 0] sel_2,
    output reg [`tagWidth  - 1 : 0] tag_2,
    output reg [`dataWidth - 1 : 0] data_2,
    //Read Port3
    input wire [`reg_sel - 1 : 0] sel_3,
    output reg [`tagWidth  - 1 : 0] tag_3,
    output reg [`dataWidth - 1 : 0] data_3,
    //Read Port4
    input wire [`reg_sel - 1 : 0] sel_4,
    output reg [`tagWidth  - 1 : 0] tag_4,
    output reg [`dataWidth - 1 : 0] data_4,
    //status
    input wire stall
);
    reg [`dataWidth - 1 : 0] data[`reg_size - 1 : 0];
    reg [`tagWidth  - 1 : 0] tag[`reg_size  - 1 : 0];
    
    integer i;
    always @ (posedge clk) begin
        if (rst || clear) begin
            for (i = 0; i < `reg_size; i = i + 1) begin
                data[i] <= clear ? data[i] : 0;
                tag[i]  <= `tagFree;
            end
        end else if (rdy) begin
            if (commit_en && commit_reg) begin
                data[commit_reg] <= commit_data;
                if (tag[commit_reg] == commit_tag && !(dp_en1 && commit_reg == dp_reg1 && !stall) && !(dp_en2 && commit_reg == dp_reg2 && !stall))
                    tag[commit_reg] <= `tagFree;
            end
            if (!stall) begin
                if (dp_en1 && dp_reg1 && !(dp_en2 && dp_reg1 == dp_reg2)) tag[dp_reg1] <= dp_tag1;
                if (dp_en2 && dp_reg2)                                    tag[dp_reg2] <= dp_tag2;
            end
        end
    end
    
	always @ (*) begin
        if (rst) begin
            data_1 = 0;
            tag_1  = `tagFree;
        end else if (commit_en && sel_1 == commit_reg && sel_1 != 0 && commit_tag == tag[sel_1]) begin
            data_1 = commit_data;
            tag_1  = `tagFree;
        end else begin
            data_1 = data[sel_1];
            tag_1  = tag [sel_1];
        end
    end
    
	always @ (*) begin
        if (rst) begin
            data_2 = 0;
            tag_2  = `tagFree;
        end else if (commit_en && sel_2 == commit_reg && sel_2 != 0 && commit_tag == tag[sel_2]) begin
            data_2 = commit_data;
            tag_2  = `tagFree;
        end else begin
            data_2 = data[sel_2];
            tag_2  = tag [sel_2];
        end
    end
    

	always @ (*) begin
        if (rst) begin
            data_3 = 0;
            tag_3  = `tagFree;
        end else if (commit_en && sel_3 == commit_reg && sel_3 != 0 && commit_tag == tag[sel_3]) begin
            data_3 = commit_data;
            tag_3  = `tagFree;
        end else begin
            data_3 = data[sel_3];
            tag_3  = tag [sel_3];
        end
    end
    
	
	always @ (*) begin
        if (rst) begin
            data_4 = 0;
            tag_4  = `tagFree;
        end else if (commit_en && sel_4 == commit_reg && sel_4 != 0 && commit_tag == tag[sel_4]) begin
            data_4 = commit_data;
            tag_4  = `tagFree;
        end else begin
            data_4 = data[sel_4];
            tag_4  = tag [sel_4];
        end
    end
    
endmodule 