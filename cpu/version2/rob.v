`timescale 1ns/1ps

`include "defines.vh"

module rob(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear,
    //input from Dispatcher
    input wire [`tagWidth - 1 : 0] dp_tag1_1,
    input wire [`tagWidth - 1 : 0] dp_tag2_1,
    input wire [`tagWidth - 1 : 0] dp_tag1_2,
    input wire [`tagWidth - 1 : 0] dp_tag2_2,
    input wire dpw_en1,
    input wire dpw_isbranch1,
    input wire dpw_wrrd1,
    input wire [`reg_sel - 1 : 0] dpw_addr1,
    input wire [`indexWidth - 1 : 0] dpw_PC1,
    input wire dpw_en2,
    input wire dpw_isbranch2,
    input wire dpw_wrrd2,
    input wire [`reg_sel - 1 : 0] dpw_addr2,
    input wire [`indexWidth - 1 : 0] dpw_PC2,
    //output to decoder 
    output wire dp_tag1_1ready,
    output wire dp_tag2_1ready,
    output wire dp_tag1_2ready,
    output wire dp_tag2_2ready,
    output wire [`dataWidth - 1 : 0] dp_tag1_1data,
    output wire [`dataWidth - 1 : 0] dp_tag2_1data,
    output wire [`dataWidth - 1 : 0] dp_tag1_2data,
    output wire [`dataWidth - 1 : 0] dp_tag2_2data,
    //output to regfile
    output wire com_wrrd,
    output wire [`reg_sel - 1 : 0] com_addr,
    output wire [`dataWidth - 1 : 0] com_data,
    output wire [`tagWidth - 1 : 0] com_tag,
    output wire com_clear,
    output wire [`addrWidth - 1 : 0] com_target,
    //input from FUs
    input wire ex_alu_en_1,
    input wire [`dataWidth - 1 : 0] ex_alu_data_1,
    input wire [`tagWidth - 1 : 0] ex_alu_tag_1,
    input wire ex_alu_en_2,
    input wire [`dataWidth - 1 : 0] ex_alu_data_2,
    input wire [`tagWidth - 1 : 0] ex_alu_tag_2,
    input wire ex_ls_en,
    input wire [`dataWidth - 1 : 0] ex_ls_data,
    input wire [`tagWidth - 1 : 0] ex_ls_tag,
    input wire ex_branch_en,
    input wire ex_branch_taken,
    input wire [`tagWidth - 1 : 0] ex_branch_tag,
    input wire [`addrWidth - 1 : 0] ex_branch_target,
    //stauts
    input wire stall, 
    output wire rob_free,
    output reg [`rob_sel - 1 : 0] alloc_ptr_1,
    output reg [`rob_sel - 1 : 0] alloc_ptr_2,
    output reg [`rob_sel - 1 : 0] com_ptr,
    output wire pdt_en,
    output wire pdt_choice,
    output wire [`indexWidth - 1 : 0] pdt_PC
);
    reg [`dataWidth - 1 : 0] data[`rob_size - 1 : 0];
    reg [`rob_size - 1 : 0]  valid, isbranch, wrrd, taken;
    reg [`reg_sel - 1 : 0]   dest[`rob_size - 1 : 0];
    reg [`indexWidth - 1 : 0] PC[`rob_size - 1 : 0]; 
    reg [`rob_sel : 0] ent_cnt;
    wire [2 : 0] status;
    
    assign dp_tag1_1ready = dp_tag1_1 == `tagFree ? 1 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag1_1 ? 1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag1_1 ? 1 : 
                            ex_ls_en && ex_ls_tag == dp_tag1_1 ? 1 : valid[dp_tag1_1[`cutRange]];
                            
    assign dp_tag2_1ready = dp_tag2_1 == `tagFree ? 1 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag2_1 ? 1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag2_1 ? 1 : 
                            ex_ls_en && ex_ls_tag == dp_tag2_1 ? 1 : valid[dp_tag2_1[`cutRange]];    
                                   
    assign dp_tag1_2ready = dp_tag1_2 == `tagFree ? 1 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag1_2 ? 1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag1_2 ? 1 : 
                            ex_ls_en && ex_ls_tag == dp_tag1_2 ? 1 : valid[dp_tag1_2[`cutRange]];
                            
                                     
    assign dp_tag2_2ready = dp_tag2_2 == `tagFree ? 1 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag2_2 ? 1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag2_2 ? 1 : 
                            ex_ls_en && ex_ls_tag == dp_tag2_2 ? 1 : valid[dp_tag2_2[`cutRange]];     
                                                                                                  
    assign dp_tag1_1data = dp_tag1_1 == `tagFree ? 0 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag1_1 ? ex_alu_data_1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag1_1 ? ex_alu_data_2 : 
                            ex_ls_en && ex_ls_tag == dp_tag1_1 ? ex_ls_data : data[dp_tag1_1[`cutRange]];
                            
    assign dp_tag2_1data = dp_tag2_1 == `tagFree ? 0 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag2_1 ? ex_alu_data_1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag2_1 ? ex_alu_data_2 : 
                            ex_ls_en && ex_ls_tag == dp_tag2_1 ? ex_ls_data : data[dp_tag2_1[`cutRange]];    
                                   
    assign dp_tag1_2data = dp_tag1_2 == `tagFree ? 0 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag1_2 ? ex_alu_data_1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag1_2 ? ex_alu_data_2 : 
                            ex_ls_en && ex_ls_tag == dp_tag1_2 ? ex_ls_data : data[dp_tag1_2[`cutRange]];
                            
    assign dp_tag2_2data = dp_tag2_2 == `tagFree ? 0 : 
                            ex_alu_en_1 && ex_alu_tag_1 == dp_tag2_2 ? ex_alu_data_1 :
                            ex_alu_en_2 && ex_alu_tag_2 == dp_tag2_2 ? ex_alu_data_2 : 
                            ex_ls_en && ex_ls_tag == dp_tag2_2 ? ex_ls_data : data[dp_tag2_2[`cutRange]];     
    
    wire com_en;
    assign com_en     = valid[com_ptr];
    assign com_wrrd   = valid[com_ptr] & wrrd[com_ptr] & !isbranch[com_ptr];
    assign com_addr   = dest[com_ptr];
    assign com_data   = data[com_ptr];
    assign com_tag    = com_ptr;
    assign com_clear  = valid[com_ptr] & isbranch[com_ptr] & taken[com_ptr] != wrrd[com_ptr];
    assign pdt_en     = valid[com_ptr] & isbranch[com_ptr];
    assign pdt_PC     = PC[com_ptr];
    assign pdt_choice  = taken[com_ptr];
    assign com_target = data[com_ptr];
      
    assign rob_free = ent_cnt + dpw_en1 + dpw_en2 <= `rob_size ? 1 : 0;
    assign status = {dpw_en1, dpw_en2, com_en};
    
    integer i;
    integer counter;
    integer counter1;
    integer counter2; 
    always @ (posedge clk) begin
        if (rst || clear) begin
            alloc_ptr_1 <= 0;
            alloc_ptr_2 <= 1;
            com_ptr  <= 0;
            ent_cnt <= 0;
            valid <= 0;
            isbranch <= 0;
            wrrd <= 0;
            taken <= 0;
            if (rst) counter = 0;
            else counter = counter + 1;
            if (rst) counter1 = 0;
            else counter1 = counter1 + 1;
            if (rst) counter2 = 0;
            else counter2 = counter2 + 1;
            for (i = 0; i < `rob_size; i = i + 1) begin
                data[i] <= 0;
                dest[i] <= `tagFree;
                PC[i] <= 0;
            end
        end else if (rdy) begin
            if (ex_alu_en_1) begin
                data[ex_alu_tag_1[`cutRange]] <= ex_alu_data_1;
                valid[ex_alu_tag_1[`cutRange]] <= 1;
            end
            if (ex_alu_en_2) begin
                data[ex_alu_tag_2[`cutRange]] <= ex_alu_data_2;
                valid[ex_alu_tag_2[`cutRange]] <= 1;
            end
            if (ex_branch_en) begin
                taken[ex_branch_tag[`cutRange]] <= ex_branch_taken;
                valid[ex_branch_tag[`cutRange]] <= 1;
                data[ex_branch_tag[`cutRange]] <= ex_branch_target;
            end
            if (ex_ls_en) begin
                data[ex_ls_tag[`cutRange]] <= ex_ls_data;
                valid[ex_ls_tag[`cutRange]] <= 1;
            end 
            if (!stall) begin           
                if (dpw_en1) begin
                    isbranch[alloc_ptr_1] <= dpw_isbranch1;
                    wrrd[alloc_ptr_1]     <= dpw_wrrd1;
                    dest[alloc_ptr_1]     <= dpw_addr1;
                    PC[alloc_ptr_1]       <= dpw_PC1;
                end
                if (dpw_en2) begin
                    isbranch[alloc_ptr_2] <= dpw_isbranch2;
                    wrrd[alloc_ptr_2]     <= dpw_wrrd2;
                    dest[alloc_ptr_2]     <= dpw_addr2;
                    PC[alloc_ptr_2]       <= dpw_PC2;            
                end
                if (com_en) begin
                    counter = counter + 1;
                    if (isbranch[com_ptr]) counter2 = counter2 + 1;
                    valid[com_ptr] <= 0;
                end
                case (status)
                    3'b110 : begin
                        alloc_ptr_1 <= alloc_ptr_1 + 2;
                        alloc_ptr_2 <= alloc_ptr_2 + 2;
                        ent_cnt <= ent_cnt + 2;
                    end
                    3'b100 : begin
                        alloc_ptr_1 <= alloc_ptr_1 + 1;
                        alloc_ptr_2 <= alloc_ptr_2 + 1;
                        ent_cnt <= ent_cnt + 1;
                    end
                    3'b000 : begin
                    
                    end
                    3'b111 : begin
                        alloc_ptr_1 <= alloc_ptr_1 + 2;
                        alloc_ptr_2 <= alloc_ptr_2 + 2;
                        com_ptr <= com_ptr + 1;
                        ent_cnt <= ent_cnt + 1;
                    end
                    3'b101 : begin
                        alloc_ptr_1 <= alloc_ptr_1 + 1;
                        alloc_ptr_2 <= alloc_ptr_2 + 1;
                        com_ptr <= com_ptr + 1;
                    end
                    3'b001 : begin
                        com_ptr <= com_ptr + 1;
                        ent_cnt <= ent_cnt - 1;
                    end
                    default : begin
                    
                    end
                endcase
            end else begin
                if (com_en) begin
                    counter = counter + 1;
                    if (isbranch[com_ptr]) counter2 = counter2 + 1;
                    valid[com_ptr] <= 0;
                    com_ptr <= com_ptr + 1;
                    ent_cnt <= ent_cnt - 1;
                end
            end
        end
    end
endmodule