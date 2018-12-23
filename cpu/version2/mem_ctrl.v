`timescale 1ns / 1ps

`include "defines.vh"

module icache_set(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from PC
    input wire [`addrWidth - 1 : 0] PC_1,
    input wire [`addrWidth - 1 : 0] PC_2,
    input wire insert_enable,
    input wire [`instWidth - 1 : 0] inst_insert,
    //output to mem_ctrl,
    output wire hit_1,
    output wire [`instWidth - 1 : 0] inst_out_1,
    output wire hit_2,
    output wire [`instWidth - 1 : 0] inst_out_2
);
    localparam cache_size = 64;
    localparam index_width = 6;
    localparam tag_width = 24;

    reg [`instWidth - 1 : 0] data [cache_size - 1 : 0];
    reg [tag_width  - 1 : 0] tag  [cache_size - 1 : 0];
    reg                      valid[cache_size - 1 : 0];
 
    wire [tag_width - 1 : 0] tag_in_1, tag_in_2;    
    wire [index_width - 1 : 0] index_in_1, index_in_2;
    
    assign tag_in_1   = PC_1[31 : 8];
    assign index_in_1 = PC_1[7 : 2];
    assign inst_out_1  = data[index_in_1];
    assign hit_1 = (valid[index_in_1] && tag[index_in_1] == tag_in_1) ? 1 : 0;
    
    assign tag_in_2   = PC_2[31 : 8];
    assign index_in_2 = PC_2[7 : 2];
    assign inst_out_2  = data[index_in_2];
    assign hit_2 = (valid[index_in_2] && tag[index_in_2] == tag_in_2) ? 1 : 0;
  
    integer i;
    always @ (posedge clk) begin
        if (rst) begin
           for (i = 0; i < cache_size; i = i + 1) begin
               data[i] <= 0;
               tag[i] <= 0;
               valid[i] <= 0;
           end
       end else if (rdy) begin
            if (insert_enable) begin
                data[index_in_1] <= inst_insert;
                tag[index_in_1]  <= tag_in_1;
                valid[index_in_1] <= 1;
            end
       end
    end
endmodule

module icache(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from PC
    input wire [`addrWidth - 1 : 0] PC_1,
    input wire [`addrWidth - 1 : 0] PC_2,
    input wire insert_enable,
    input wire [`instWidth - 1 : 0] inst_insert,
    //output to mem_ctrl,
    output wire hit_1,
    output wire [`instWidth - 1 : 0] inst_out_1,
    output wire hit_2,
    output wire [`instWidth - 1 : 0] inst_out_2
);
    reg                      insert_enable_[1 : 0];
    wire                      hit1_1, hit2_1, hit1_2, hit2_2;
    wire [`instWidth - 1 : 0] inst1_1, inst2_1, inst1_2, inst2_2; 
    wire mux;
    wire [5 : 0]   index_insert;
    reg  [63 : 0]  router;
      
    assign index_insert = PC_1[7 : 2];
    assign mux          = router[index_insert];
    
    icache_set set_0(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .PC_1(PC_1),
        .PC_2(PC_2),
        .insert_enable(insert_enable_[0]),
        .inst_insert(inst_insert),
        .hit_1(hit1_1),
        .inst_out_1(inst1_1),
        .hit_2(hit2_1),
        .inst_out_2(inst2_1)
    );
    
    icache_set set_1(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .PC_1(PC_1),
        .PC_2(PC_2),
        .insert_enable(insert_enable_[1]),
        .inst_insert(inst_insert),
        .hit_1(hit1_2),
        .inst_out_1(inst1_2),
        .hit_2(hit2_2),
        .inst_out_2(inst2_2)
    );
    
    assign hit_1 = hit1_1 | hit1_2;
    assign inst_out_1 = hit1_1 ? inst1_1 : inst1_2;
    assign hit_2 = hit2_1 | hit2_2;
    assign inst_out_2 = hit2_1 ? inst2_1 : inst2_2;
    
    always @ (*) begin
        insert_enable_[mux] = insert_enable;
        insert_enable_[~mux] = 0;
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            router <= 0;
        end else if (rdy) begin
            if (insert_enable) begin
                router[index_insert] <= ~router[index_insert];
            end
        end
    end
    
endmodule

module mem_ctrl(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear,
    //port with CORE
    input wire [3 : 0] rw_flag,
    input wire [2 * `addrWidth - 1 : 0] addr,
    input wire [2 * 2 - 1 : 0] len,
    input wire [2 * `dataWidth - 1 : 0] data_in,
    input wire [`addrWidth - 1 : 0] PC_2,
    output reg [2 * `dataWidth - 1 : 0] data_out,
    output reg [1 : 0] busy,
    output reg [1 : 0] done,
    //port with RAM
    output wire ram_rw_flag, // (read : 1, write : 0)
    output wire [`addrWidth - 1 : 0] ram_addr,
    output wire [`ram_data_bus_width - 1 : 0] ram_data_out,
    input  wire [`ram_data_bus_width - 1 : 0] ram_data_in,
    //port with PC
    output wire cache_hit1,
    output wire [`instWidth - 1 : 0] cache_inst1,
    output wire cache_hit2,
    output wire [`instWidth - 1 : 0] cache_inst2
);
    localparam STATE_IDLE  = 4'b0000;
    localparam STATE_LOAD0 = 4'b0001;
    localparam STATE_LOAD1 = 4'b0010;
    localparam STATE_LOAD2 = 4'b0011;
    localparam STATE_LOAD3 = 4'b0100;
    localparam STATE_LOAD4 = 4'b0101;
    localparam STATE_IO0   = 4'b0110;
    localparam STATE_J0    = 4'b0111;
    localparam STATE_IO1   = 4'b1000;
    localparam STATE_J1    = 4'b1001;
    localparam STATE_IO2   = 4'b1010;
    localparam STATE_J2    = 4'b1011;
    localparam STATE_IO3   = 4'b1100;
    localparam STATE_J3    = 4'b1101;
    localparam STATE_S     = 4'b1110;
     
    wire hit1;
    wire [`instWidth - 1 : 0] cache_inst_out1;
    
    assign cache_hit1 = hit1;
    assign cache_inst1 = cache_inst_out1;
    
    icache icache(
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .PC_1(addr[31 : 0]),
        .PC_2(PC_2),
        .insert_enable(done[0]),
        .inst_insert(data_out[31 : 0]),
        .hit_1(hit1),
        .inst_out_1(cache_inst_out1),
        .hit_2(cache_hit2),
        .inst_out_2(cache_inst2)
    );
    
    reg [3 : 0]                           state;
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
    
    task send_serving;
        begin
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
                 state               <= pending_rw_flag[1][0] ? (pending_addr[1][17 : 16] == 2'b11 ? STATE_IO0 : STATE_LOAD0) : STATE_S; 
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
                state               <= STATE_LOAD0; 
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
                state               <= rw_flag[2] ? (addr[49 : 48] == 2'b11 ? STATE_IO0 : STATE_LOAD0) : STATE_S; 
             end else if (rw_flag[1 : 0] != 0) begin
                if (!hit1) begin
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
                    state               <= STATE_LOAD0;
                end else begin
                    serving_rw_flag <= 0;
                    serving_addr <= 0;
                    serving_len <= 0;
                    serving_data_out[0] <= 0;
                    serving_data_out[1] <= 0;
                    serving_data_out[2] <= 0;
                    serving_data_out[3] <= 0;
                    serving_byte_cnt <= 0;
                    pending_flag[0]  <= 0;
                    serving_port_id <= 0;
                    state <= STATE_IDLE;
                end
             end else begin
                serving_rw_flag <= 0;
                serving_addr <= 0;
                serving_len <= 0;
                serving_data_out[0] <= 0;
                serving_data_out[1] <= 0;
                serving_data_out[2] <= 0;
                serving_data_out[3] <= 0;
                serving_byte_cnt <= 0;
                serving_port_id <= 0;
                state <= STATE_IDLE;
             end
        end
    endtask
    
    integer i;
    always @ (posedge clk) begin
        if (rst || clear) begin
            state        <= STATE_IDLE;
            pending_flag <= 0;
            for (i = 0; i < 2; i = i + 1) begin
                pending_rw_flag[i] <= 0;
                pending_addr[i] <= 0;
                pending_len[i] <= 0;
                pending_data_in[i] <= 0;
            end
            data_out     <= 0;
            busy         <= 0;
            done         <= 0;
            serving_rw_flag <= 0;
            serving_addr <= 0;
            serving_len <= 0;
            serving_data_out[0] <= 0;
            serving_data_out[1] <= 0;
            serving_data_out[2] <= 0;
            serving_data_out[3] <= 0;
            serving_byte_cnt <= 0;
            serving_port_id <= 0;
        end else if (rdy) begin
            //port 0 pending
            done   <= 0;
            if (rw_flag[1 : 0] != 0 && pending_flag[0] == 0) begin
                if (!hit1) begin
                    pending_flag[0]    <= 1;
                    pending_rw_flag[0] <= rw_flag[1 : 0];
                    pending_addr[0]    <= addr   [31 : 0];
                    pending_len[0]     <= len    [1 : 0];
                    pending_data_in[0] <= data_in[31 : 0];     
                    busy[0]            <= 1;
                end else begin
                    busy[0]            <= 0;
                    done[0]            <= 0;
                    data_out[31 : 0]   <= cache_inst_out1;
                end
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
                        state               <= rw_flag[2] ? (addr[49 : 48] == 2'b11 ? STATE_IO0 : STATE_LOAD0) : STATE_S; 
                    end else if (rw_flag[1 : 0] != 0) begin
                        if (!hit1) begin
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
                            state               <= STATE_LOAD0; 
                        end else begin
                            serving_rw_flag <= 0;
                            serving_addr <= 0;
                            serving_len <= 0;
                            serving_data_out[0] <= 0;
                            serving_data_out[1] <= 0;
                            serving_data_out[2] <= 0;
                            serving_data_out[3] <= 0;
                            serving_byte_cnt <= 0;
                            serving_port_id <= 0;
                            pending_flag[0]    <= 0;
                            state              <= STATE_IDLE;
                        end
                    end else begin
                        serving_rw_flag <= 0;
                        serving_addr <= 0;
                        serving_len <= 0;
                        serving_data_out[0] <= 0;
                        serving_data_out[1] <= 0;
                        serving_data_out[2] <= 0;
                        serving_data_out[3] <= 0;
                        serving_byte_cnt <= 0;
                        serving_port_id <= 0;
                        state               <= STATE_IDLE;
                    end
                end
                STATE_LOAD0 : begin
                    serving_byte_cnt <= serving_byte_cnt + 1;
                    serving_addr     <= serving_addr + 1; 
                    state <= STATE_LOAD1;
                end
                STATE_LOAD1 : begin
                    if (serving_port_id == 0) data_out[7 : 0] <= ram_data_in;
                    else                      data_out[39 : 32] <= ram_data_in;
                    if (serving_len == 2'b00) begin
                        send_serving();
                    end else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_LOAD2;
                    end
                end
                STATE_LOAD2 : begin
                    if (serving_port_id == 0) data_out[15 : 8] <= ram_data_in;
                    else                      data_out[47 : 40] <= ram_data_in;
                    if (serving_len == 2'b01) begin
                        send_serving();
                    end else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_LOAD3;
                    end
                end
                STATE_LOAD3 : begin
                    if (serving_port_id == 0) data_out[23 : 16] <= ram_data_in;
                    else                      data_out[55 : 48] <= ram_data_in;
                    if (serving_len == 2'b10) begin
                        send_serving();
                    end else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_LOAD4;
                    end                
                end
                STATE_LOAD4 : begin
                    if (serving_port_id == 0) data_out[31 : 24] <= ram_data_in;
                    else                      data_out[63 : 56] <= ram_data_in;
                    send_serving();
                end
                STATE_IO0 : begin
                    state <= STATE_J0;
                end
                STATE_J0 : begin
                    if (serving_port_id == 0) data_out[7 : 0] <= ram_data_in;
                    else                      data_out[39 : 32] <= ram_data_in;
                    if (serving_len == 2'b00) send_serving();
                    else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_IO1;
                    end
                end
                STATE_IO1 : begin
                    state <= STATE_J1;
                end
                STATE_J1 : begin
                    if (serving_port_id == 0) data_out[15 : 8] <= ram_data_in;
                    else                      data_out[47 : 40] <= ram_data_in;
                    if (serving_len == 2'b01) send_serving();
                    else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_IO2;
                    end
                end
                STATE_IO2 : begin
                    state <= STATE_J2;
                end
                STATE_J2 : begin
                    if (serving_port_id == 0) data_out[23 : 16] <= ram_data_in;
                    else                      data_out[55 : 48] <= ram_data_in;
                    if (serving_len == 2'b11) send_serving();
                    else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state <= STATE_IO3;
                    end
                end
                STATE_IO3 : begin
                    state <= STATE_J3;
                end
                STATE_J3 : begin
                    if (serving_port_id == 0) data_out[31 : 24] <= ram_data_in;
                    else                      data_out[63 : 56] <= ram_data_in;
                    send_serving();
                end
                STATE_S : begin
                    if (serving_byte_cnt == serving_len) send_serving();
                    else begin
                        serving_byte_cnt <= serving_byte_cnt + 1;
                        serving_addr     <= serving_addr + 1;
                        state            <= STATE_S;
                    end
                end
            endcase
        end
    end
endmodule