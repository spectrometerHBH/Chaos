`timescale 1ns / 1ps

module predictor(
    input wire clk,
    input wire rst,
    input wire rdy,
    //input from PC
    input wire insert_en,
    input wire mux,
    input wire [`addrWidth - 1 : 0] PC1,
    input wire [`addrWidth - 1 : 0] PC2,
    //output to PC
    output wire predict1,
    output wire predict2,
    //input from ROB
    input wire modify_en,
    input wire clear,
    input wire choice
);
    /*
    //static(always taken)
    assign predict1 = 1;
    assign predict2 = 1;
    */
    
    /*
    //static(always untaken)
    assign predict = 0;
    */

        
    //global history table
    localparam index_width      = 6;
    localparam ght_size         = 64;
    //localparam gh_width         = 20;
    reg                               ght[ght_size - 1 : 0];
    reg         [index_width - 1 : 0] gh;
    reg         [index_width - 1 : 0] ghb;
    
    assign predict1 = ght[gh];
    assign predict2 = ght[gh];
    
    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < ght_size; i = i + 1) begin
                ght[i] <= 0;                
            end
            gh <= 0;
            ghb <= 0;
        end else if (rdy) begin
            if (modify_en) begin
                if (clear) gh <= (ghb << 1) | choice;
                ght[ghb] <= choice;
                ghb      <= (ghb << 1) | choice;
            end
            if (insert_en && !clear) begin
                gh       <= (gh << 1) | (mux ? predict2 : predict1);
            end
        end
    end
    
endmodule
