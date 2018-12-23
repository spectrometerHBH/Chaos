`timescale 1ns/1ps

`include "defines.vh"

module Regfile(
    input wire clk,
    input wire rst,
    input wire rdy,
    //Write Port with Dispatcher
    input wire dp_en_1,
    input wire [`reg_sel  - 1 : 0] selw_1,
    input wire [`tagWidth - 1 : 0] tagw_1,
    input wire dp_en_2,
    input wire [`reg_sel  - 1 : 0] selw_2,
    input wire [`tagWidth - 1 : 0] tagw_2,
    //Write Port with ex
    input wire ex_alu_en_1,
    input wire [`dataWidth - 1 : 0] ex_alu_data_1,
    input wire [`reg_sel  - 1 : 0] ex_alu_reg_1,
    input wire [`tagWidth - 1 : 0] ex_alu_tag_1,
    input wire ex_alu_en_2,
    input wire [`dataWidth - 1 : 0] ex_alu_data_2,
    input wire [`reg_sel  - 1 : 0] ex_alu_reg_2,
    input wire [`tagWidth - 1 : 0] ex_alu_tag_2,
    input wire ex_ls_en,
    input wire [`dataWidth - 1 : 0] ex_ls_data,
    input wire [`reg_sel  - 1 : 0] ex_ls_reg,
    input wire [`tagWidth - 1 : 0] ex_ls_tag,
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
    //stall
    input wire stall
);
    reg [`dataWidth - 1 : 0] data[`reg_size - 1 : 0];
    reg [`tagWidth  - 1 : 0] tag[`reg_size  - 1 : 0];

    wire clear1, clear2, clear3;
    assign clear1 = ex_alu_en_1 && ex_alu_reg_1 != 0 && tag[ex_alu_reg_1] == ex_alu_tag_1;
    assign clear2 = ex_alu_en_2 && ex_alu_reg_2 != 0 && tag[ex_alu_reg_2] == ex_alu_tag_2;
    assign clear3 = ex_ls_en && ex_ls_reg != 0 && tag[ex_ls_reg] == ex_ls_tag;
                
    integer i;
	always @ (posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `reg_size; i = i + 1) begin
                data[i] <= 0;
                tag[i]  <= `tagFree;  
            end
        end else if (rdy) begin
            if (clear1 && !(dp_en_1 && ex_alu_reg_1 == selw_1) && !(dp_en_2 && ex_alu_reg_1 == selw_2)) begin
                data[ex_alu_reg_1] <= ex_alu_data_1;
                tag[ex_alu_reg_1] <= `tagFree;
            end
            if (clear2 && !(dp_en_1 && ex_alu_reg_2 == selw_1) && !(dp_en_2 && ex_alu_reg_2 == selw_2)) begin
                data[ex_alu_reg_2] <= ex_alu_data_2;
                tag[ex_alu_reg_2] <= `tagFree;
            end
            if (clear3 && !(dp_en_1 && ex_ls_reg == selw_1) && !(dp_en_2 && ex_ls_reg == selw_2)) begin
                data[ex_ls_reg] <= ex_ls_data;
                tag[ex_ls_reg] <= `tagFree;
            end
            if (dp_en_1 && !stall) begin
                if (selw_1 && !(dp_en_2 && selw_1 == selw_2)) begin
                    tag[selw_1] <= tagw_1;
                end
            end
            if (dp_en_2 && !stall) begin
                if (selw_2) begin
                    tag[selw_2] <= tagw_2;
                end
            end
        end
	end

	always @ (*) begin
        if (rst) begin
            data_1 = 0;
            tag_1  = `tagFree;
        end else if (clear1 && sel_1 == ex_alu_reg_1) begin
            data_1 = ex_alu_data_1;
            tag_1  = `tagFree;
        end else if (clear2 && sel_1 == ex_alu_reg_2) begin
            data_1 = ex_alu_data_2;
            tag_1  = `tagFree;
        end else if (clear3 && sel_1 == ex_ls_reg) begin
            data_1 = ex_ls_data;
            tag_1  = `tagFree;
        end else begin
            data_1 = data[sel_1];
            tag_1  = tag [sel_1];
        end
    end
    
    //reg debug;
	always @ (*) begin
        if (rst) begin
            //debug = 0;
            data_2 = 0;
            tag_2  = `tagFree;
        end else if (clear1 && sel_2 == ex_alu_reg_1) begin
            //debug = 1;
            data_2 = ex_alu_data_1;
            tag_2  = `tagFree;
        end else if (clear2 && sel_2 == ex_alu_reg_2) begin
            data_2 = ex_alu_data_2;
            tag_2  = `tagFree;
        end else if (clear3 && sel_2 == ex_ls_reg) begin
            data_2 = ex_ls_data;
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
        end else if (clear1 && sel_3 == ex_alu_reg_1) begin
            data_3 = ex_alu_data_1;
            tag_3  = `tagFree;
        end else if (clear2 && sel_3 == ex_alu_reg_2) begin
            data_3 = ex_alu_data_2;
            tag_3  = `tagFree;
        end else if (clear3 && sel_3 == ex_ls_reg) begin
            data_3 = ex_ls_data;
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
        end else if (clear1 && sel_4 == ex_alu_reg_1) begin
            data_4 = ex_alu_data_1;
            tag_4  = `tagFree;
        end else if (clear2 && sel_4 == ex_alu_reg_2) begin
            data_4 = ex_alu_data_2;
            tag_4  = `tagFree;
        end else if (clear3 && sel_4 == ex_ls_reg) begin
            data_4 = ex_ls_data;
            tag_4  = `tagFree;
        end else begin
            data_4 = data[sel_4];
            tag_4  = tag [sel_4];
        end
    end
endmodule 