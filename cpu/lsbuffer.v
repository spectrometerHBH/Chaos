`timescale 1ns / 1ps

`include "defines.vh"

module lsbuffer_ent(
    input wire clk,
    input wire rst,
    input wire rdy,
    //allocate
    input wire busy,
    input wire ls_enable,
    input wire [`newopWidth - 1 : 0] ls_op,
    input wire [`dataWidth  - 1 : 0] ls_base,
    input wire [`tagWidth   - 1 : 0] ls_basetag,
    input wire [`dataWidth  - 1 : 0] ls_src,
    input wire [`tagWidth   - 1 : 0] ls_srctag,
    input wire [`addrWidth  - 1 : 0] ls_Imm,
    input wire [`tagWidth   - 1 : 0] ls_dest,
    input wire [`reg_sel    - 1 : 0] ls_reg,
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
    //output to ex_ls
    output wire [`dataWidth - 1 : 0] ex_src1,
    output wire [`dataWidth - 1 : 0] ex_src2,
    output wire [`dataWidth - 1 : 0] ex_reg,
    output wire [`newopWidth - 1 : 0] ex_lsop,
    output wire [`tagWidth  - 1 : 0] ex_dest,
    output wire [`reg_sel   - 1 : 0] ex_dreg,
    //output to rs_ls
    output wire ready 
);
    reg [`dataWidth - 1 : 0] data1, data2, Imm;
    reg [`tagWidth  - 1 : 0] tag1,  tag2;
    reg [`tagWidth  - 1 : 0] dest;
    reg [`newopWidth - 1 : 0] op;
    reg [`reg_sel   - 1 : 0] dreg;
    wire [`dataWidth  - 1 : 0] next_data1, next_data2;
    wire [`tagWidth   - 1 : 0] next_tag1, next_tag2;
    
    assign ex_src1 = (tag1 != `tagFree && next_tag1 == `tagFree) ? next_data1 : data1;
    assign ex_src2 = Imm;
    assign ex_reg  = (tag2 != `tagFree && next_tag2 == `tagFree) ? next_data2 : data2; 
    assign ex_lsop = op;
    assign ex_dest = dest;
    assign ex_dreg = dreg;
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
            dreg  <= 0;
        end else if (rdy) begin
            if (ls_enable) begin
                data1 <= ls_base;
                tag1  <= ls_basetag;
                data2 <= ls_src;
                tag2  <= ls_srctag;
                dest  <= ls_dest;
                Imm   <= ls_Imm;
                op    <= ls_op;
                dreg  <= ls_reg;
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

module lsbuffer(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //input from Decoder
    input wire  ls_enable_1,
    input wire  [`newopWidth - 1 : 0] ls_op_1,
    input wire  [`dataWidth  - 1 : 0] ls_base_1,
    input wire  [`tagWidth   - 1 : 0] ls_basetag_1,
    input wire  [`dataWidth  - 1 : 0] ls_src_1,
    input wire  [`tagWidth   - 1 : 0] ls_srctag_1,
    input wire  [`addrWidth  - 1 : 0] ls_Imm_1,
    input wire  [`tagWidth   - 1 : 0] ls_dest_1,
    input wire  [`reg_sel    - 1 : 0] ls_reg_1,
    input wire  ls_enable_2,
    input wire  [`newopWidth - 1 : 0] ls_op_2,
    input wire  [`dataWidth  - 1 : 0] ls_base_2,
    input wire  [`tagWidth   - 1 : 0] ls_basetag_2,
    input wire  [`dataWidth  - 1 : 0] ls_src_2,
    input wire  [`tagWidth   - 1 : 0] ls_srctag_2,
    input wire  [`addrWidth  - 1 : 0] ls_Imm_2,
    input wire  [`tagWidth   - 1 : 0] ls_dest_2,
    input wire  [`reg_sel    - 1 : 0] ls_reg_2,
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
    input wire ex_ls_done,
    //output to ex_ls
    output reg ex_ls_en,
    output reg [`dataWidth - 1 : 0] exsrc1_out,
    output reg [`dataWidth - 1 : 0] exsrc2_out,
    output reg [`dataWidth - 1 : 0] exreg_out,
    output reg [`newopWidth - 1 : 0] exlsop_out,
    output reg [`tagWidth - 1 : 0] exdest_out,
    output reg [`reg_sel - 1 : 0] exdreg_out,
    //status
    input  wire stall,
    output reg [`lsbuf_sel - 1 : 0] allocate_addr_1,
    output reg [`lsbuf_sel - 1 : 0] allocate_addr_2,
    output wire lsbuffer_free
);
    reg  [`lsbuf_size - 1 : 0] busy;
    wire [`lsbuf_size - 1 : 0] ready;
    wire [2 : 0]               status;
    reg  [`lsbuf_sel - 1 : 0] issue_addr;
    reg  [`lsbuf_sel     : 0] ent_cnt; 
    wire [`dataWidth - 1 : 0] exsrc1  [`lsbuf_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exsrc2  [`lsbuf_size - 1 : 0];
    wire [`dataWidth - 1 : 0] exreg   [`lsbuf_size - 1 : 0];
    wire [`newopWidth - 1 : 0] exlsop [`lsbuf_size - 1 : 0];
    wire [`tagWidth   - 1 : 0] exdest [`lsbuf_size - 1 : 0];
    wire [`reg_sel   - 1 : 0] exdreg  [`lsbuf_size - 1 : 0];
    
    reg                       alloc_en[`lsbuf_size - 1 : 0];
    reg [`newopWidth - 1 : 0] alloc_op[`lsbuf_size - 1 : 0];
    reg [`dataWidth  - 1 : 0] alloc_base[`lsbuf_size - 1 : 0];
    reg [`tagWidth   - 1 : 0] alloc_basetag[`lsbuf_size - 1 : 0];
    reg [`dataWidth  - 1 : 0] alloc_src[`lsbuf_size - 1 : 0];
    reg [`tagWidth   - 1 : 0] alloc_srctag[`lsbuf_size - 1 : 0];
    reg [`addrWidth  - 1 : 0] alloc_Imm[`lsbuf_size - 1 : 0];
    reg [`tagWidth   - 1 : 0] alloc_dest[`lsbuf_size - 1 : 0];
    reg [`reg_sel    - 1 : 0] alloc_reg[`lsbuf_size - 1 : 0];
    wire issue_en;
    
    assign lsbuffer_free = ent_cnt + ls_enable_1 + ls_enable_2 < `lsbuf_size ? 1 : 0;
    assign issue_en      = ready[issue_addr] && ex_ls_done;
    assign status = {ls_enable_1, ls_enable_2, issue_en}; 
     
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            busy            <= 0;
            allocate_addr_1 <= 0;
            allocate_addr_2 <= 1;
            issue_addr      <= 0;
            ent_cnt         <= 0;
        end else if (rdy) begin
            if (!stall) begin
                if (ls_enable_1) busy[allocate_addr_1] <= 1;
                if (ls_enable_2) busy[allocate_addr_2] <= 1;
                if (issue_en)    busy[issue_addr] <= 0;

                case (status)
                    3'b110 : begin
                        allocate_addr_1 <= allocate_addr_1 + 2;
                        allocate_addr_2 <= allocate_addr_2 + 2;
                        ent_cnt <= ent_cnt + 2;
                    end
                    3'b100 : begin
                        allocate_addr_1 <= allocate_addr_1 + 1;
                        allocate_addr_2 <= allocate_addr_2 + 1;
                        ent_cnt <= ent_cnt + 1;
                    end
                    3'b000 : begin
                        
                    end
                    3'b111 : begin
                        allocate_addr_1 <= allocate_addr_1 + 2;
                        allocate_addr_2 <= allocate_addr_2 + 2;
                        issue_addr <= issue_addr + 1;
                        ent_cnt <= ent_cnt + 1;
                    end
                    3'b101 : begin
                        allocate_addr_1 <= allocate_addr_1 + 1;
                        allocate_addr_2 <= allocate_addr_2 + 1;
                        issue_addr <= issue_addr + 1;
                    end
                    3'b001 : begin
                        issue_addr <= issue_addr + 1;
                        ent_cnt <= ent_cnt - 1;
                    end
                    default : begin
                    
                    end
                endcase
            end else begin
                if (issue_en) begin
                    busy[issue_addr] <= 0;
                    issue_addr <= issue_addr + 1;
                    ent_cnt <= ent_cnt - 1;
                end
            end
        end
    end
    
    integer k;
    always @ (*) begin
        for (k = 0; k < `lsbuf_size; k = k + 1) begin
            alloc_en[k] = 0;
            alloc_op[k] = `NOP;
            alloc_base[k] = 0;
            alloc_basetag[k] = `tagFree;
            alloc_src[k] = 0;
            alloc_srctag[k] = `tagFree;
            alloc_Imm[k] = 0;
            alloc_dest[k] = `tagFree;
            alloc_reg[k] = 0;
        end
        if (ls_enable_1 && !stall) begin
            alloc_en[allocate_addr_1] = 1;
            alloc_op[allocate_addr_1] = ls_op_1;
            alloc_base[allocate_addr_1] = ls_base_1;
            alloc_basetag[allocate_addr_1] = ls_basetag_1;
            alloc_src[allocate_addr_1] = ls_src_1;
            alloc_srctag[allocate_addr_1] = ls_srctag_1;
            alloc_Imm[allocate_addr_1] = ls_Imm_1;
            alloc_dest[allocate_addr_1] = ls_dest_1;
            alloc_reg[allocate_addr_1] = ls_reg_1;
        end
        if (ls_enable_2 && !stall) begin
            alloc_en[allocate_addr_2] = 1;
            alloc_op[allocate_addr_2] = ls_op_2;
            alloc_base[allocate_addr_2] = ls_base_2;
            alloc_basetag[allocate_addr_2] = ls_basetag_2;
            alloc_src[allocate_addr_2] = ls_src_2;
            alloc_srctag[allocate_addr_2] = ls_srctag_2;
            alloc_Imm[allocate_addr_2] = ls_Imm_2;
            alloc_dest[allocate_addr_2] = ls_dest_2;
            alloc_reg[allocate_addr_2] = ls_reg_2;
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
                .ls_enable(alloc_en[i]),
                .ls_op(alloc_op[i]),
                .ls_base(alloc_base[i]),
                .ls_basetag(alloc_basetag[i]),
                .ls_src(alloc_src[i]),
                .ls_srctag(alloc_srctag[i]),
                .ls_Imm(alloc_Imm[i]),
                .ls_dest(alloc_dest[i]),
                .ls_reg(alloc_reg[i]),
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
                .ex_reg(exreg[i]),
                .ex_lsop(exlsop[i]),
                .ex_dest(exdest[i]),
                .ex_dreg(exdreg[i]),
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
            exdest_out <= `tagFree;
            exdreg_out <= 0;
        end else if (rdy) begin
            ex_ls_en <= 0;
            exsrc1_out <= 0;
            exsrc2_out <= 0;
            exreg_out <= 0;
            exlsop_out <= 0;
            exdest_out <= `tagFree;
            exdreg_out <= 0; 
            if (issue_en) begin
                ex_ls_en <= 1;
                exsrc1_out <= exsrc1[issue_addr];
                exsrc2_out <= exsrc2[issue_addr];
                exreg_out  <= exreg [issue_addr];
                exlsop_out <= exlsop[issue_addr];
                exdest_out <= exdest[issue_addr];
                exdreg_out <= exdreg[issue_addr];
            end
        end
    end
endmodule
