`timescale 1ns / 1ps

`include "defines.vh"

module mem_ctrl(
    input wire clk,
    input wire rst,
    //port with CORE
    input wire [3 : 0] rw_flag,
    input wire [2 * `addrWidth - 1 : 0] addr,
    input wire [2 * 2 - 1 : 0] len,
    input wire [2 * `dataWidth - 1 : 0] data_in,
    output reg [2 * `dataWidth - 1 : 0] data_out,
    output reg [1 : 0] busy,
    output reg [1 : 0] done,
    //port with RAM
    output wire ram_rw_flag, // (read : 1, write : 0)
    output wire [`addrWidth - 1 : 0] ram_addr,
    output wire [`ram_data_bus_width - 1 : 0] ram_data_out,
    input  wire [`ram_data_bus_width - 1 : 0] ram_data_in
);
    localparam STATE_IDLE = 1'b0;
    localparam STATE_BUSY = 1'b1;
    
    reg                                   state;
    reg [1 : 0]                           pending_flag;  
    reg [1 : 0]                           pending_rw_flag[1 : 0];
    reg [`addrWidth - 1 : 0]              pending_addr[1 : 0];
    reg [1 : 0]                           pending_len[1 : 0];
    reg [`dataWidth - 1 : 0]              pending_data_in[1 : 0];
    
    reg [1 : 0]                           serving_rw_flag;
    reg [`addrWidth - 1 : 0]              serving_addr;
    reg [1 : 0]                           serving_len;
    reg [`ram_data_bus_width - 1 : 0]     serving_data_out[3 : 0];
    reg [1 : 0]                           serving_byte_cnt;   
    reg                                   serving_port_id;
    
    assign ram_rw_flag  = serving_rw_flag[1];
    assign ram_addr     = serving_addr;
    assign ram_data_out = serving_data_out[serving_byte_cnt];
    
    always @ (negedge clk) begin
        if (rst) begin
            state        <= STATE_IDLE;
            pending_flag <= 0;
            busy         <= 0;
            done         <= 0;
        end else begin
            //port 0 pending
            done   <= 0;
            if (rw_flag[1 : 0] != 0 && pending_flag[0] == 0) begin
                pending_flag[0]    <= 1;
                pending_rw_flag[0] <= rw_flag[1 : 0];
                pending_addr[0]    <= addr   [31 : 0];
                pending_len[0]     <= len    [1 : 0];
                pending_data_in[0] <= data_in[31 : 0];     
                busy[0]            <= 1;
            end
            //port 1 pending
            if (rw_flag[3 : 2] != 0 && pending_flag[1] == 0) begin
                pending_flag[1]    <= 1;
                pending_rw_flag[1] <= rw_flag[3 : 2];
                pending_addr[1]    <= addr   [63 : 32];
                pending_len[1]     <= len    [3 : 2];
                pending_data_in[1] <= data_in[63 : 32];
                busy[1]            <= 1;
            end
            case (state) 
                STATE_IDLE : begin
                    if (rw_flag[3 : 2] != 0) begin
                        serving_rw_flag     <= rw_flag[3 : 2];
                        serving_addr        <= addr   [63 : 32];
                        serving_len         <= len    [3 : 2];
                        serving_data_out[0] <= data_in[39 : 32];
                        serving_data_out[1] <= data_in[47 : 40];
                        serving_data_out[2] <= data_in[55 : 48];
                        serving_data_out[3] <= data_in[63 : 56];
                        serving_byte_cnt    <= 0;
                        pending_flag[1]     <= 0;
                        serving_port_id     <= 1; 
                        state               <= STATE_BUSY; 
                    end else if (rw_flag[1 : 0] != 0) begin
                        serving_rw_flag     <= rw_flag[1 : 0];
                        serving_addr        <= addr   [31 : 0];
                        serving_len         <= len    [1 : 0];
                        serving_data_out[0] <= data_in[7 : 0];
                        serving_data_out[1] <= data_in[15 : 8];
                        serving_data_out[2] <= data_in[23 : 16];
                        serving_data_out[3] <= data_in[31 : 24];
                        serving_byte_cnt     <= 0;
                        pending_flag[0]     <= 0; 
                        serving_port_id     <= 0;
                        state               <= STATE_BUSY;
                    end else begin
                        state               <= STATE_IDLE;
                    end
                end
                STATE_BUSY : begin
                    if (serving_port_id == 0) begin
                        case (serving_byte_cnt) 
                            2'b00 : data_out[7 : 0] <= ram_data_in;
                            2'b01 : data_out[15 : 8] <= ram_data_in;
                            2'b10 : data_out[23 : 16] <= ram_data_in;
                            2'b11 : data_out[31 : 24] <= ram_data_in;
                        endcase
                    end else begin
                        case (serving_byte_cnt) 
                            2'b00 : data_out[39 : 32] <= ram_data_in;
                            2'b01 : data_out[47 : 40] <= ram_data_in;
                            2'b10 : data_out[55 : 48] <= ram_data_in;
                            2'b11 : data_out[63 : 56] <= ram_data_in;
                        endcase
                    end
                    if (serving_byte_cnt == serving_len) begin
                        busy[serving_port_id] <= 0;
                        done[serving_port_id] <= 1;
                        if (pending_flag[1]) begin
                             serving_rw_flag     <= pending_rw_flag[1];
                             serving_addr        <= pending_addr   [1];
                             serving_len         <= pending_len    [1];
                             serving_data_out[0] <= pending_data_in[1][7 : 0];
                             serving_data_out[1] <= pending_data_in[1][15 : 8];
                             serving_data_out[2] <= pending_data_in[1][23 : 16];
                             serving_data_out[3] <= pending_data_in[1][31 : 24];
                             serving_byte_cnt    <= 0;
                             pending_flag[1]     <= 0;
                             serving_port_id     <= 1; 
                             state               <= STATE_BUSY; 
                        end else if (pending_flag[0]) begin
                            serving_rw_flag     <= pending_rw_flag[0];
                            serving_addr        <= pending_addr   [0];
                            serving_len         <= pending_len    [0];
                            serving_data_out[0] <= pending_data_in[0][7 : 0];
                            serving_data_out[1] <= pending_data_in[0][15 : 8];
                            serving_data_out[2] <= pending_data_in[0][23 : 16];
                            serving_data_out[3] <= pending_data_in[0][31 : 24];
                            serving_byte_cnt    <= 0;
                            pending_flag[0]     <= 0;
                            serving_port_id     <= 0; 
                            state               <= STATE_BUSY; 
                        end else if (rw_flag[3 : 2] != 0) begin
                            serving_rw_flag     <= rw_flag[3 : 2];
                            serving_addr        <= addr   [63 : 32];
                            serving_len         <= len    [3 : 2];
                            serving_data_out[0] <= data_in[39 : 32];
                            serving_data_out[1] <= data_in[47 : 40];
                            serving_data_out[2] <= data_in[55 : 48];
                            serving_data_out[3] <= data_in[63 : 56];
                            serving_byte_cnt    <= 0;
                            pending_flag[1]     <= 0;
                            serving_port_id     <= 1; 
                            state               <= STATE_BUSY; 
                         end else if (rw_flag[1 : 0] != 0) begin
                            serving_rw_flag     <= rw_flag[1 : 0];
                            serving_addr        <= addr   [31 : 0];
                            serving_len         <= len    [1 : 0];
                            serving_data_out[0] <= data_in[7 : 0];
                            serving_data_out[1] <= data_in[15 : 8];
                            serving_data_out[2] <= data_in[23 : 16];
                            serving_data_out[3] <= data_in[31 : 24];
                            serving_byte_cnt     <= 0;
                            pending_flag[0]     <= 0; 
                            serving_port_id     <= 0;
                            state               <= STATE_BUSY;
                         end else begin
                            state               <= STATE_IDLE;
                         end
                    end else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr     + 1;
                        state            <= STATE_BUSY;
                    end
                end
            endcase
        end
    end
endmodule
