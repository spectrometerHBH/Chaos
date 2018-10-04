`timescale 1ns/1ps

`include "defines.v"

module ROB(
    //input from Decoder
    input wire [`tagWidth - 1 : 0] tagCheck1,
    input wire [`tagWidth - 1 : 0] tagCheck2,
    //output to Decoder
    output wire tag1Ready,
    output wire tag2Ready
);

endmodule