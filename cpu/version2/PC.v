`timescale 1ns/1ps

`include "defines.vh"

module PC(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //output to predictor
    output reg predictor_en,
    output wire predictor_mux,
    //input from predictor
    input wire predict1,
    input wire predict2,
    //output to Decoder1
    output reg Decoder_enable1,
    output reg [`addrWidth - 1 : 0] PC_Decoder1,
    output reg [`instWidth - 1 : 0] inst_Decoder1,
    output reg predict_Decoder1,
    //input from Decoder1
    input wire [`addrWidth - 1 : 0] Decoder1_taken,
    //output to Decoder2
    output reg Decoder_enable2,
    output reg [`addrWidth - 1 : 0] PC_Decoder2,
    output reg [`instWidth - 1 : 0] inst_Decoder2,
    output reg predict_Decoder2,
    //input from Decoder2
    input wire [`addrWidth - 1 : 0] Decoder2_taken,
    //input from alu
    input wire jump_dest_valid,
    input wire [`addrWidth  - 1 : 0] jump_dest,
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
    input  wire stall,
    input  wire clear,
    input  wire [`addrWidth - 1 : 0] true_target
);
    localparam STATE_IDLE   = 3'b000;
    localparam STATE_OnRecv = 3'b001;
    localparam STATE_OnJump = 3'b010;
    localparam STATE_OnFull = 3'b011;
    localparam STATE_OnAddr = 3'b100;
    
    reg [2 : 0]              PC_state;
    reg                      mux;
    wire jump1, jump2, jump_mem, jump_cache;
    wire branch1, branch2, branch_mem, branch_cache;
    wire [`instWidth - 1 : 0] inst_in1, inst_in2;
    
    assign len   = 2'b11;  
    assign jump_mem     = read_data[6] & read_data[2];
    assign jump_cache   = cache_data1[6] & cache_data1[2];
    assign jump1        = cache_hit1 ? jump_cache : jump_mem;
    assign jump2        = cache_data2[6] & cache_data2[2];
    
    assign branch_mem   = read_data[6] & (~read_data[2]);
    assign branch_cache = cache_data1[6] & (~cache_data1[2]);
    assign branch1      = cache_hit1 ? branch_cache : branch_mem;
    assign branch2      = cache_data2[6] & (~cache_data2[2]);
    assign predictor_mux = branch1 ? 0 : 1;
    assign inst_in1   = (cache_hit1 ? cache_data1 : read_data); 
    assign inst_in2   = (cache_hit2 ? cache_data2 : 32'b0);
    
    task send_decode;
        begin
            Decoder_enable1 <= 1;
            PC_Decoder1     <= PC;
            inst_Decoder1   <= inst_in1;
            predict_Decoder1 <= predict1;
            predictor_en    <= 0;
            //debug_counter   <= debug_counter + 1;
            if (jump1) begin
                Decoder_enable2 <= 0;
                rw_flag         <= 0;
                next_PC         <= next_PC;
                PC_state        <= STATE_OnJump;
                PC              <= PC;
            end else if (branch1) begin
                predictor_en    <= 1;
                Decoder_enable2 <= 0;
                rw_flag         <= 0;
                next_PC         <= next_PC;
                PC_state        <= STATE_OnAddr;
                mux             <= 0;
                PC              <= PC;
            end else begin
                if (cache_hit2) begin
                    Decoder_enable2 <= 1;
                    PC_Decoder2     <= next_PC;
                    inst_Decoder2   <= inst_in2;
                    predict_Decoder2 <= predict2;
                    //debug_counter   <= debug_counter + 2;
                    if (jump2) begin
                        rw_flag     <= 0;
                        next_PC     <= next_PC;
                        PC_state    <= STATE_OnJump;
                        PC          <= PC;
                    end else if (branch2) begin
                        predictor_en <= 1;
                        rw_flag     <= 0;
                        next_PC     <= next_PC;
                        PC_state    <= STATE_OnAddr;
                        mux         <= 1;
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
    
    always @(posedge clk) begin
        if (rst || clear) begin
            PC              <= rst ? 0 : true_target;
            next_PC         <= rst ? 4 : true_target + 4;
            rw_flag         <= 0;
            Decoder_enable1 <= 0;
            PC_Decoder1     <= 0;
            inst_Decoder1   <= 0;
            Decoder_enable2 <= 0;
            PC_Decoder2     <= 0;
            inst_Decoder2   <= 0; 
            //debug_counter   <= 0;
            PC_state        <= STATE_IDLE;
            mux             <= 0;
            predict_Decoder1 <= 0;
            predict_Decoder2 <= 0;
            predictor_en    <= 0;
        end else if (rdy) begin
            case (PC_state)
                STATE_IDLE : begin
                    predictor_en <= 0;
                    rw_flag  <= 1;
                    next_PC  <= next_PC;
                    PC_state <= STATE_OnRecv; 
                    PC       <= PC;
                end
                STATE_OnRecv : begin
                    predictor_en    <= 0;
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
                    predictor_en    <= 0;
                    if (!stall) begin
                        Decoder_enable1 <= 0;
                        Decoder_enable2 <= 0;
                    end
                    if (jump_dest_valid) begin
                        PC       <= jump_dest;
                        rw_flag  <= 1;
                        next_PC  <= jump_dest + 4;
                        PC_state <= STATE_OnRecv; 
                    end else  begin
                        rw_flag  <= 0;
                        PC       <= PC;
                        next_PC  <= next_PC;
                        PC_state <= STATE_OnJump;
                    end 
                end
                STATE_OnFull : begin
                    predictor_en <= 0;
                    if (stall) begin
                        PC_state <= STATE_OnFull;
                        rw_flag  <= 0;
                    end else send_decode();
                end
                STATE_OnAddr : begin  
                    predictor_en <= 0;
                    if (!stall) begin
                        Decoder_enable1 <= 0;
                        Decoder_enable2 <= 0;
                    end
                    rw_flag         <= 1;
                    next_PC         <= mux ? Decoder2_taken + 4 : Decoder1_taken + 4;
                    PC_state        <= STATE_OnRecv;
                    PC              <= mux ? Decoder2_taken : Decoder1_taken;
                end
            endcase
        end
    end
endmodule