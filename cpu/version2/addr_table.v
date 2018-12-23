`timescale 1ns / 1ps

`include "defines.vh"

module addr_table(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire [5 : 0] alu_busy,
    input wire [5 : 0] alu_ready,
    input wire [2 : 0] branch_busy_i,
    input wire [2 : 0] branch_ready_i,
    output wire [2 : 0] alu_free_1,
    output wire [2 : 0] alu_free_2,
    output wire [2 : 0] alu_ready_1,
    output wire [2 : 0] alu_ready_2,
    output wire [1 : 0] branch_free,
    output wire [1 : 0] branch_ready
);
    reg [2 : 0] table_1[63 : 0], table_2[63 : 0];
    reg [1 : 0] table_3[15 : 0];
    
    assign alu_free_1 = table_1[alu_busy];
    assign alu_free_2 = table_2[alu_busy];
    assign alu_ready_1 = table_1[alu_ready];
    assign alu_ready_2 = table_2[alu_ready];
    assign branch_free = table_3[branch_busy_i];
    assign branch_ready = table_3[branch_ready_i];
    
    always @ (posedge clk) begin
        if (rst) begin
            table_1[6'b000000] <= 3'b000;
            table_1[6'b000001] <= 3'b001;
            table_1[6'b000010] <= 3'b000;
            table_1[6'b000011] <= 3'b010;
            table_1[6'b000100] <= 3'b000;
            table_1[6'b000101] <= 3'b001;
            table_1[6'b000110] <= 3'b000;
            table_1[6'b000111] <= 3'b011;
            table_1[6'b001000] <= 3'b000;
            table_1[6'b001001] <= 3'b001;
            table_1[6'b001010] <= 3'b000;
            table_1[6'b001011] <= 3'b010;
            table_1[6'b001100] <= 3'b000;
            table_1[6'b001101] <= 3'b001;
            table_1[6'b001110] <= 3'b000;
            table_1[6'b001111] <= 3'b100;
            table_1[6'b010000] <= 3'b000;
            table_1[6'b010001] <= 3'b001;
            table_1[6'b010010] <= 3'b000;
            table_1[6'b010011] <= 3'b010;
            table_1[6'b010100] <= 3'b000;
            table_1[6'b010101] <= 3'b001;
            table_1[6'b010110] <= 3'b000;
            table_1[6'b010111] <= 3'b011;
            table_1[6'b011000] <= 3'b000;
            table_1[6'b011001] <= 3'b001;
            table_1[6'b011010] <= 3'b000;
            table_1[6'b011011] <= 3'b010;
            table_1[6'b011100] <= 3'b000;
            table_1[6'b011101] <= 3'b001;
            table_1[6'b011110] <= 3'b000;
            table_1[6'b011111] <= 3'b101;
            table_1[6'b100000] <= 3'b000;
            table_1[6'b100001] <= 3'b001;
            table_1[6'b100010] <= 3'b000;
            table_1[6'b100011] <= 3'b010;
            table_1[6'b100100] <= 3'b000;
            table_1[6'b100101] <= 3'b001;
            table_1[6'b100110] <= 3'b000;
            table_1[6'b100111] <= 3'b011;
            table_1[6'b101000] <= 3'b000;
            table_1[6'b101001] <= 3'b001;
            table_1[6'b101010] <= 3'b000;
            table_1[6'b101011] <= 3'b010;
            table_1[6'b101100] <= 3'b000;
            table_1[6'b101101] <= 3'b001;
            table_1[6'b101110] <= 3'b000;
            table_1[6'b101111] <= 3'b100;
            table_1[6'b110000] <= 3'b000;
            table_1[6'b110001] <= 3'b001;
            table_1[6'b110010] <= 3'b000;
            table_1[6'b110011] <= 3'b010;
            table_1[6'b110100] <= 3'b000;
            table_1[6'b110101] <= 3'b001;
            table_1[6'b110110] <= 3'b000;
            table_1[6'b110111] <= 3'b011;
            table_1[6'b111000] <= 3'b000;
            table_1[6'b111001] <= 3'b001;
            table_1[6'b111010] <= 3'b000;
            table_1[6'b111011] <= 3'b010;
            table_1[6'b111100] <= 3'b000;
            table_1[6'b111101] <= 3'b001;
            table_1[6'b111110] <= 3'b000;
            table_1[6'b111111] <= 3'b111;
            
            table_2[6'b000000] <= 3'b001;
            table_2[6'b000001] <= 3'b010;
            table_2[6'b000010] <= 3'b010;
            table_2[6'b000011] <= 3'b011;
            table_2[6'b000100] <= 3'b001;
            table_2[6'b000101] <= 3'b011;
            table_2[6'b000110] <= 3'b011;
            table_2[6'b000111] <= 3'b100;
            table_2[6'b001000] <= 3'b001;
            table_2[6'b001001] <= 3'b010;
            table_2[6'b001010] <= 3'b010;
            table_2[6'b001011] <= 3'b100;
            table_2[6'b001100] <= 3'b001;
            table_2[6'b001101] <= 3'b100;
            table_2[6'b001110] <= 3'b100;
            table_2[6'b001111] <= 3'b101;
            table_2[6'b010000] <= 3'b001;
            table_2[6'b010001] <= 3'b010;
            table_2[6'b010010] <= 3'b010;
            table_2[6'b010011] <= 3'b011;
            table_2[6'b010100] <= 3'b001;
            table_2[6'b010101] <= 3'b011;
            table_2[6'b010110] <= 3'b011;
            table_2[6'b010111] <= 3'b101;
            table_2[6'b011000] <= 3'b001;
            table_2[6'b011001] <= 3'b010;
            table_2[6'b011010] <= 3'b010;
            table_2[6'b011011] <= 3'b101;
            table_2[6'b011100] <= 3'b001;
            table_2[6'b011101] <= 3'b101;
            table_2[6'b011110] <= 3'b101;
            table_2[6'b011111] <= 3'b111;
            table_2[6'b100000] <= 3'b001;
            table_2[6'b100001] <= 3'b010;
            table_2[6'b100010] <= 3'b010;
            table_2[6'b100011] <= 3'b011;
            table_2[6'b100100] <= 3'b001;
            table_2[6'b100101] <= 3'b011;
            table_2[6'b100110] <= 3'b011;
            table_2[6'b100111] <= 3'b100;
            table_2[6'b101000] <= 3'b001;
            table_2[6'b101001] <= 3'b010;
            table_2[6'b101010] <= 3'b010;
            table_2[6'b101011] <= 3'b100;
            table_2[6'b101100] <= 3'b001;
            table_2[6'b101101] <= 3'b100;
            table_2[6'b101110] <= 3'b100;
            table_2[6'b101111] <= 3'b111;
            table_2[6'b110000] <= 3'b001;
            table_2[6'b110001] <= 3'b010;
            table_2[6'b110010] <= 3'b010;
            table_2[6'b110011] <= 3'b011;
            table_2[6'b110100] <= 3'b001;
            table_2[6'b110101] <= 3'b011;
            table_2[6'b110110] <= 3'b011;
            table_2[6'b110111] <= 3'b111;
            table_2[6'b111000] <= 3'b001;
            table_2[6'b111001] <= 3'b010;
            table_2[6'b111010] <= 3'b010;
            table_2[6'b111011] <= 3'b111;
            table_2[6'b111100] <= 3'b001;
            table_2[6'b111101] <= 3'b111;
            table_2[6'b111110] <= 3'b111;
            table_2[6'b111111] <= 3'b111;
            
            table_3[3'b000] <= 2'b00;
            table_3[3'b001] <= 2'b01;
            table_3[3'b010] <= 2'b00;
            table_3[3'b011] <= 2'b10;
            table_3[3'b100] <= 2'b00;
            table_3[3'b101] <= 2'b01;
            table_3[3'b110] <= 2'b00;
            table_3[3'b111] <= 2'b11;
        end
    end
        
endmodule