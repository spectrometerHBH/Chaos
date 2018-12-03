`timescale 1ns / 1ps

`include "defines.vh"

module cache(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from PC
    input wire [1 : 0] rw_flag,                 //[0] for read, [1] for write, both zero for stall
    input wire [`addrWidth - 1 : 0] PC,
    input wire [1 : 0] len, 
    //output to PC
    output reg [`instWidth - 1: 0] data_out,
    output reg cache_busy,
    output reg cache_done,
    //output to mem_ctrl
    output reg [1 : 0] rw_flag_out,
    output reg [`addrWidth - 1 : 0] PC_out,
    output reg [1 : 0] len_out, 
    //input from mem_ctrl
    input wire [`instWidth - 1 : 0] read_data,
    input wire mem_busy,
    input wire mem_done
);
    localparam cache_size = 128;
    localparam index_width = 7;
    localparam tag_width = 23;
    localparam STATE_IDLE = 1'b0;
    localparam STATE_BUSY = 1'b1;
    
    reg state;
    reg [`dataWidth - 1 : 0] data [cache_size - 1 : 0];
    reg [tag_width  - 1 : 0] tag  [cache_size - 1 : 0];
    reg                      valid[cache_size - 1 : 0];

    wire [tag_width - 1 : 0] tag_in, tag_serving;
    wire [`dataWidth - 1 : 0] data_in;    
    wire [index_width - 1 : 0] index_in, index_serving;
    wire hit;
   
    assign tag_in   = PC[31 : 9];
    assign index_in = PC[8 : 2];
    assign data_in  = data[index_in];
    assign hit = (valid[index_in] && tag[index_in] == tag_in) ? 1 : 0;
    assign tag_serving   = PC_out[31 : 9];
    assign index_serving = PC_out[8 : 2];
     
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            rw_flag_out <= 0;
            PC_out      <= 0;
            len_out     <= 0;
            state       <= STATE_IDLE;
            data_out    <= 0;
            cache_busy  <= 0;
            cache_done  <= 0;
            for (i = 0; i < cache_size; i = i + 1) begin
                data[i] <= 0;
                tag[i] <= 0;
                valid[i] <= 0;
            end
        end else if (rdy) begin
            case (state)
                STATE_IDLE : begin
                    if (rw_flag) begin
                        if (hit) begin
                            rw_flag_out <= 0;
                            state <= STATE_IDLE;
                            data_out <= data_in;
                            cache_busy <= 0;
                            cache_done <= 1;                            
                        end else begin
                            rw_flag_out <= rw_flag;
                            PC_out <= PC;
                            len_out <= len;
                            state <= STATE_BUSY;
                            cache_busy <= 1;
                            cache_done <= 0;
                        end
                    end else begin
                        rw_flag_out <= 0;
                        state <= STATE_IDLE;   
                        cache_busy <= 0;
                        cache_done <= 0; 
                    end
                end
                STATE_BUSY : begin
                    if (mem_done) begin
                        rw_flag_out <= 0;
                        state <= STATE_IDLE;
                        data_out <= read_data;
                        cache_busy <= 0;
                        cache_done <= 1;
                        data[index_serving] <= read_data;
                        tag[index_serving]  <= tag_serving;
                        valid[index_serving] <= 1; 
                    end else begin
                        rw_flag_out <= 0;
                        state <= STATE_BUSY;
                        cache_busy <= 1;
                        cache_done <= 0;
                    end
                end
            endcase
        end
    end    
endmodule

