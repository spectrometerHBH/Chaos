`timescale 1ns/1ps

`include "defines.vh"

module PC(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //output to Decoder1
    output reg Decoder_enable1,
    output reg [`addrWidth - 1 : 0] PC_Decoder1,
    output reg [`instWidth - 1 : 0] inst_Decoder1,
    //output to Decoder2
    output reg Decoder_enable2,
    output reg [`addrWidth - 1 : 0] PC_Decoder2,
    output reg [`instWidth - 1 : 0] inst_Decoder2,
    //input from alu
    input wire jump_dest_valid,
    input wire [`addrWidth  - 1 : 0] jump_dest,
    //input from branch
    input wire branch_dest_valid,
    input wire [`addrWidth  - 1 : 0] branch_dest,
    //output to mem_ctrl
    output reg [1 : 0] rw_flag, //[0] for read, [1] for write, both zero for stall
    output reg [`addrWidth - 1 : 0] PC,
    output wire [1 : 0] len, 
    output reg [`addrWidth - 1 : 0] next_PC,
    //input from mem_ctrl
    input  wire [`instWidth - 1: 0] read_data,
    input  wire mem_busy,
    input  wire mem_done,
    input  wire cache_hit1,
    input  wire [`instWidth - 1 : 0] cache_data1,
    input  wire cache_hit2,
    input  wire [`instWidth - 1 : 0] cache_data2,
    //stall
    input  wire stall
);
    localparam STATE_IDLE   = 2'b00;
    localparam STATE_OnRecv = 2'b01;
    localparam STATE_OnJump = 2'b10;
    localparam STATE_OnFull = 2'b11;
    
    reg [1 : 0]              PC_state;
    wire jump1, jump2, jump_mem, jump_cache;
    wire [`instWidth - 1 : 0] inst_in1, inst_in2;
    
    //reg [31 : 0] debug_counter;
    //wire debug_stall;
    //assign debug_stall = debug_counter >= 7463 ? 0 : 0;
    
    assign len   = 2'b11;  
    assign jump_mem   = read_data[6];
    assign jump_cache = cache_data1[6];
    assign jump1      = cache_hit1 ? jump_cache : jump_mem;
    assign jump2      = cache_data2[6];
    //assign inst_in1   = debug_stall ? 0 : (cache_hit1 ? cache_data1 : read_data); 
    //assign inst_in2   = debug_stall ? 0 : (cache_hit2 ? cache_data2 : 32'b0);
    assign inst_in1   = (cache_hit1 ? cache_data1 : read_data); 
    assign inst_in2   = (cache_hit2 ? cache_data2 : 32'b0);
    
    task send_decode;
        begin
            Decoder_enable1 <= 1;
            PC_Decoder1     <= PC;
            inst_Decoder1   <= inst_in1;
            //debug_counter   <= debug_counter + 1;
            if (jump1) begin
                Decoder_enable2 <= 0;
                rw_flag         <= 0;
                next_PC         <= next_PC;
                PC_state        <= STATE_OnJump;
                PC              <= PC;
            end else begin
                if (cache_hit2) begin
                    Decoder_enable2 <= 1;
                    PC_Decoder2     <= next_PC;
                    inst_Decoder2   <= inst_in2;
                    //debug_counter   <= debug_counter + 2;
                    if (jump2) begin
                        rw_flag     <= 0;
                        next_PC     <= next_PC;
                        PC_state    <= STATE_OnJump;
                        PC          <= PC;
                    end else begin
                        rw_flag     <= 1;
                        next_PC     <= next_PC + 8;
                        PC_state    <= STATE_OnRecv;
                        PC          <= PC + 8;
                    end
                end else begin
                    Decoder_enable2 <= 0;
                    rw_flag         <= 1;
                    next_PC         <= next_PC + 4;
                    PC_state        <= STATE_OnRecv;
                    PC              <= next_PC;
                end
            end
        end
    endtask
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC              <= 0;
            next_PC         <= 4;
            rw_flag         <= 0;
            Decoder_enable1 <= 0;
            PC_Decoder1     <= 0;
            inst_Decoder1   <= 0;
            Decoder_enable2 <= 0;
            PC_Decoder2     <= 0;
            inst_Decoder2   <= 0; 
            //debug_counter   <= 0;
            PC_state <= STATE_IDLE;
        end else if (rdy) begin
            case (PC_state)
                STATE_IDLE : begin
                    rw_flag  <= 1;
                    next_PC  <= next_PC;
                    PC_state <= STATE_OnRecv; 
                    PC       <= PC;
                end
                STATE_OnRecv : begin
                    if (mem_done || cache_hit1) begin
                        if (!stall) begin
                            send_decode();
                        end else begin
                            rw_flag  <= 0;
                            PC_state <= STATE_OnFull;
                        end
                    end else begin
                        if (!stall) begin
                            Decoder_enable1 <= 0;
                            Decoder_enable2 <= 0;
                        end
                        rw_flag  <= 0;
                        next_PC  <= next_PC;
                        PC_state <= STATE_OnRecv;
                        PC       <= PC;
                        next_PC  <= next_PC;
                    end
                end
                STATE_OnJump : begin
                    if (!stall) begin
                        Decoder_enable1 <= 0;
                        Decoder_enable2 <= 0;
                    end
                    if (jump_dest_valid) begin
                        PC       <= jump_dest;
                        rw_flag  <= 1;
                        next_PC  <= jump_dest + 4;
                        PC_state <= STATE_OnRecv; 
                    end else if (branch_dest_valid) begin
                        PC       <= branch_dest;
                        rw_flag  <= 1;
                        next_PC  <= branch_dest + 4;
                        PC_state <= STATE_OnRecv;
                    end else begin
                        rw_flag  <= 0;
                        PC       <= PC;
                        next_PC  <= next_PC;
                        PC_state <= STATE_OnJump;
                    end 
                end
                STATE_OnFull : begin
                    if (stall) begin
                        PC_state <= STATE_OnFull;
                        rw_flag  <= 0;
                    end else send_decode();
                end
            endcase
        end
    end
endmodule