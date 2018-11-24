`timescale 1ns/1ps

`include "defines.vh"

module PC(
    input wire clk, 
    input wire rst,
    input wire rdy,
    //output to Decoder
    output reg Decoder_enable,
    output reg [`addrWidth - 1 : 0] PC_Decoder,
    output reg [`instWidth - 1 : 0] inst_Decoder,
    //input from alu
    input wire jump_dest_valid,
    input wire [`addrWidth  - 1 : 0] jump_dest,
    //input from branch
    input wire branch_dest_valid,
    input wire [`addrWidth  - 1 : 0] branch_dest,
    //output to mem_ctrl
    output reg [1 : 0] rw_flag,                 //[0] for read, [1] for write, both zero for stall
    output reg [`addrWidth - 1 : 0] PC,
    output wire [1 : 0] len, 
    //input from mem_ctrl
    input  wire [`instWidth - 1: 0] read_data,
    input  wire mem_busy,
    input  wire mem_done,
    //input from rs_alu & ROB
    input  wire alu_free,
    input  wire ls_free,
    input  wire rob_free
);
    localparam STATE_IDLE   = 2'b00;
    localparam STATE_OnRecv = 2'b01;
    localparam STATE_OnJump = 2'b10;

    reg [`addrWidth - 1 : 0] next_PC;
    reg [1 : 0]              PC_state;
    wire jump, stall;
    
    assign len   = 2'b11;
    assign stall = ~(alu_free & rob_free & ls_free);    
    assign jump  = read_data[`classOpRange] == `classBranch || 
                   read_data[`classOpRange] == `classJAL    ||
                   read_data[`classOpRange] == `classJALR   ? 1 : 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 0;
            next_PC <= 0;
            rw_flag <= 0;
            Decoder_enable <= 0;
            PC_Decoder <= 0;
            inst_Decoder <= 0; 
            PC_state <= STATE_IDLE;
        end else if (rdy) begin
            rw_flag <= 0;
            Decoder_enable <= 0;
            PC_Decoder   <= PC;
            inst_Decoder <= 0;
            case (PC_state)
                STATE_IDLE : begin
                    if (!stall && !mem_busy) begin
                        rw_flag <= 1;
                        next_PC <= next_PC + 4;
                        PC_state <= STATE_OnRecv; 
                        PC <= next_PC;
                    end else begin
                        next_PC <= next_PC;
                        PC_state <= STATE_IDLE;
                        PC <= next_PC;
                    end
                end
                STATE_OnRecv : begin
                    if (mem_done) begin
                        Decoder_enable <= 1;
                        inst_Decoder <= read_data;
                        PC_Decoder   <= PC;
                        if (jump) begin
                            next_PC <= next_PC;
                            PC_state <= STATE_OnJump;
                            PC <= PC;                                    
                        end else begin
                            if (!stall) begin
                                rw_flag <= 1;
                                next_PC <= next_PC + 4;
                                PC_state <= STATE_OnRecv;
                                PC <= next_PC;
                            end else begin
                                next_PC <= next_PC;
                                PC_state <= STATE_IDLE;
                                PC <= next_PC;
                            end
                        end
                    end else begin
                        next_PC <= next_PC;
                        PC_state <= STATE_OnRecv;
                        PC <= PC;
                    end
                end
                STATE_OnJump : begin
                    if (jump_dest_valid) begin
                        PC <= jump_dest;
                        if (!stall) begin
                            rw_flag <= 1;
                            next_PC <= jump_dest + 4;
                            PC_state <= STATE_OnRecv;                                
                        end else begin
                            next_PC <= jump_dest;
                            PC_state <= STATE_IDLE;
                        end
                    end else if (branch_dest_valid) begin
                        PC <= branch_dest;
                        if (!stall) begin
                            rw_flag <= 1;
                            next_PC <= branch_dest + 4;
                            PC_state <= STATE_OnRecv;    
                        end else begin
                            next_PC <= branch_dest;
                            PC_state <= STATE_IDLE;
                        end
                    end else begin
                        PC      <= PC;
                        next_PC <= next_PC;
                        PC_state <= STATE_OnJump;
                    end 
                end
            endcase
        end
    end
endmodule