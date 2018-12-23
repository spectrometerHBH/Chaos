`timescale 1ns / 1ps

module ex_ls(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear,
    //input from lsbuffer
    input wire ex_ls_en,
    input wire [`dataWidth - 1 : 0] ex_src1,
    input wire [`dataWidth - 1 : 0] ex_src2,
    input wire [`dataWidth - 1 : 0] ex_reg,
    input wire [`newopWidth - 1 : 0] ex_lsop,
    input wire [`tagWidth - 1 : 0] ex_dest,
    //output to lsbuffer
    output wire ex_ls_done,
    //output to FU & ROB
    output reg en_rst,
    output reg [`dataWidth - 1 : 0] rst_data,
    output reg [`tagWidth - 1 : 0] rst_tag,
    //output to mem_ctrl
    output reg [1 : 0] rw_flag,
    output reg [`addrWidth - 1 : 0] addr,
    output reg [`dataWidth - 1 : 0] write_data,
    output reg [1 : 0] len, 
    //input from mem_ctrl
    input wire [`dataWidth - 1 : 0] read_data,
    input wire mem_busy,
    input wire mem_done
);
    localparam STATE_IDLE = 1'b0;
    localparam STATE_BUSY = 1'b1;
    
    reg state, unsign;
    wire [`addrWidth - 1 : 0] addr_;
    assign addr_ = ex_ls_en ? ex_src1 + ex_src2 : 0;
    assign ex_ls_done = (state == STATE_IDLE) ? ~ex_ls_en : 0; 

    always @ (posedge clk) begin
        if (rst || clear) begin
            state <= STATE_IDLE;
            rw_flag <= 0;
            addr <= 0;
            len  <= 0;
            en_rst <= 0;
            rst_data <= 0;
            rst_tag <= `tagFree;
            write_data <= 0;
            unsign <= 0;
        end else if (rdy) begin
            case (state)
                STATE_IDLE : begin
                    en_rst <= 0;
                    if (ex_ls_en) begin
                        addr <= addr_;    
                        case (ex_lsop)
                            `LB : begin
                                rw_flag <= 2'b01;
                                len <= 2'b00;    
                                rst_tag <= ex_dest;
                                unsign <= 0;
                            end
                            `LH : begin
                                rw_flag <= 2'b01;
                                len <= 2'b01;
                                rst_tag <= ex_dest;
                                unsign <= 0;
                            end
                            `LW : begin
                                rw_flag <= 2'b01;
                                len <= 2'b11;
                                rst_tag <= ex_dest;
                                unsign <= 0;
                            end
                            `LBU : begin
                                rw_flag <= 2'b01;
                                len <= 2'b00;
                                rst_tag <= ex_dest;
                                unsign <= 1;
                            end
                            `LHU : begin
                                rw_flag <= 2'b01;
                                len <= 2'b01;
                                rst_tag <= ex_dest;
                                unsign <= 1;
                            end
                            `SB : begin
                                rw_flag <= 2'b10;
                                len <= 2'b00;
                                rst_tag <= ex_dest;
                                write_data <= ex_reg;
                                unsign <= 0;
                            end
                            `SH : begin
                                rw_flag <= 2'b10;
                                len <= 2'b01; 
                                rst_tag <= ex_dest;
                                write_data <= ex_reg;
                                unsign <= 0;
                            end
                            `SW : begin
                                rw_flag <= 2'b10;
                                len <= 2'b11;
                                rst_tag <= ex_dest;
                                write_data <= ex_reg;
                                unsign <= 0;
                            end
                        endcase
                        state <= STATE_BUSY; 
                    end else begin
                        state <= STATE_IDLE;
                        rw_flag <= 0;
                        addr <= 0;
                        len  <= 0;
                        en_rst <= 0;
                        rst_data <= 0;
                        rst_tag <= `tagFree;
                        write_data <= 0;
                        unsign <= 0;
                    end   
                end
                STATE_BUSY : begin
                    rw_flag <= 0;
                    if (mem_done) begin
                        en_rst <= 1;
                        if (!unsign) begin
                            case (len)
                                2'b00 : rst_data <= {{(`dataWidth - 8 ){read_data[7]}} , read_data[7 : 0]};
                                2'b01 : rst_data <= {{(`dataWidth - 16){read_data[15]}}, read_data[15 : 0]};
                                2'b11 : rst_data <= read_data;
                            endcase
                        end else begin
                            case (len)
                            2'b00 : rst_data <= {{(`dataWidth - 8 ){1'b0}}, read_data[7 : 0]};
                            2'b01 : rst_data <= {{(`dataWidth - 16){1'b0}}, read_data[15 : 0]};
                            2'b11 : rst_data <= read_data;
                            endcase
                        end               
                        state <= STATE_IDLE;
                        rw_flag <= 0;
                        addr <= 0;
                        len  <= 0;
                        write_data <= 0;
                    end 
                end
            endcase
        end
    end
endmodule
