`timescale 1ns/1ps

`include "defines.v"

module PC(
    (*mark_debug = "true"*)input wire clk, 
    (*mark_debug = "true"*)input wire rst,
    //output to IF/ID
    output reg  PC_IFID_enable,
    output reg [`addrWidth - 1 : 0] PC_IFID,
    output reg [`instWidth - 1 : 0] inst_IFID,
    //input from ALU_CDB
    input wire jump_dest_valid,
    input wire [`addrWidth  - 1 : 0] jump_dest,
    //input from branchALU_CDB
    input wire branch_offset_valid,
    input wire [`addrWidth  - 1 : 0] branch_offset,
    //output to ICache
    (*mark_debug = "true"*)output reg [1 : 0] rw_flag,             //[0] for read, [1] for write, both zero for stall
    (*mark_debug = "true"*)output reg [`addrWidth - 1 : 0] PC,
    output wire [`dataWidth - 1: 0] write_data, //useless
    output wire [3 : 0] write_mask,          //useless  
    //input from ICache
    (*mark_debug = "true"*)input  wire [`instWidth - 1: 0] read_data,
    (*mark_debug = "true"*)input  wire ICache_busy,
    (*mark_debug = "true"*)input  wire ICache_done,
    //input from RS & ROB
    input  wire alu_free,
    input  wire rob_free
);
    localparam STATE_IDLE   = 3'b00;
    localparam STATE_OnRecv = 3'b01;
    localparam STATE_OnJump = 2'b10;
    localparam STATE_OnFull = 2'b11;

    reg [`addrWidth - 1 : 0] next_PC;
    (*mark_debug = "true"*)reg [1 : 0]              PC_state;
    wire jump;
    reg branch_finish;    
    assign jump = read_data[`classOpRange] == `classBranch || 
                  read_data[`classOpRange] == `classAUIPC  ||
                  read_data[`classOpRange] == `classJAL    ||
                  read_data[`classOpRange] == `classJALR   ? 1 : 0;

    always @(negedge clk) begin
        if (rst) begin
            next_PC        <= 0;
            branch_finish  <= 0;
        end else begin
            branch_finish <= 0;
            case (PC_state)
                STATE_OnJump : begin
                    if (jump_dest_valid) begin
                        next_PC <= jump_dest;
                        branch_finish <= 1;
                    end else if (branch_offset_valid) begin
                        next_PC <= PC + branch_offset;
                        branch_finish <= 1;
                    end else next_PC <= PC;
                end
                default : begin
                    next_PC <= PC;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC_state       <= STATE_IDLE;
            PC             <= 0;
            PC_IFID_enable <= 0;
            PC_IFID        <= 0;
            inst_IFID      <= 0;
            rw_flag        <= 0;
        end else begin
            case (PC_state)
                STATE_IDLE : begin
                    if (alu_free && rob_free) begin
                        // no fetching | no branching | free
                        rw_flag        <= 1;
                        PC_IFID_enable <= 0;
                        PC_state       <= STATE_OnRecv;
                        PC             <= PC;
                    end else begin
                        // no fetching | no branching | full
                        rw_flag        <= 0;
                        PC_IFID_enable <= 0;
                        PC_state       <= STATE_OnFull;
                        PC             <= PC;
                    end
                end
                STATE_OnRecv : begin
                    if (ICache_done) begin
                        PC_IFID_enable <= 1;
                        PC_IFID        <= PC;
                        inst_IFID      <= read_data;  
                        if (jump) begin
                            // fetch finish and is jump instr
                            rw_flag  <= 0;
                            PC_state <= STATE_OnJump;
                            PC       <= PC;    
                        end else if (alu_free && rob_free) begin
                            // fetch finish and not jump instr and free
                            rw_flag  <= 1;
                            PC_state <= STATE_OnRecv;
                            PC       <= PC + 4;
                        end else begin
                            // fetch finish and not jump instr and not free (impossible)
                            rw_flag <= 0;
                            PC_state <= STATE_IDLE;
                            PC       <= PC + 4;
                        end
                    end else begin
                        //fetch waiting
                        PC_IFID_enable <= 0;
                        rw_flag        <= 0;
                        PC_state       <= STATE_OnRecv;
                        PC             <= PC; 
                    end
                end
                STATE_OnJump : begin
                    if (branch_finish) begin
                        //Jump finish
                        if (alu_free && rob_free) begin
                            //free
                            PC_IFID_enable <= 0;
                            rw_flag        <= 1;
                            PC_state       <= STATE_OnRecv;
                            PC <= next_PC;
                        end else begin
                            //not free
                            PC_IFID_enable <= 0;
                            rw_flag        <= 0;
                            PC_state       <= STATE_OnFull;  
                            PC <= next_PC;
                        end
                    end else begin
                        //Jump waiting
                        PC_IFID_enable <= 0;
                        rw_flag        <= 0;
                        PC_state       <= STATE_OnJump;
                        PC             <= PC; 
                    end
                end
                STATE_OnFull : begin
                    if (alu_free && rob_free) begin
                        PC_IFID_enable <= 0;
                        rw_flag        <= 1;
                        PC_state       <= STATE_OnRecv;
                        PC             <= PC;
                    end else begin
                        PC_IFID_enable <= 0;
                        rw_flag        <= 1;
                        PC_state       <= STATE_OnFull;
                        PC             <= PC; 
                    end
                end
            endcase
            //rw_flag <= 1;
        end
    end

endmodule