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
    input wire [`indexWidth - 1 : 0] modify_PC,
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

    /*
    //-----------------------global history table
    localparam index_width      = 6;
    localparam ght_size         = 64;
    //localparam gh_width         = 20;
    reg         ght[ght_size - 1 : 0];
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
    end*/
    
    /*
    //---------------------local 2-bit saturate counter
    localparam table_size = 64;
    reg    [1 : 0] counter[table_size - 1 : 0];
    
    assign predict1 = counter[PC1[`indexWidth + 1 : 2]][1];
    assign predict2 = counter[PC2[`indexWidth + 1 : 2]][1];
    
    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < table_size; i = i + 1)
                counter[i] <= 2'b00;
        end else if (rdy) begin
            if (modify_en) begin
                case (counter[modify_PC])
                    2'b00 : counter[modify_PC] <= choice ? 2'b01 : 2'b00;
                    2'b01 : counter[modify_PC] <= choice ? 2'b10 : 2'b00;
                    2'b10 : counter[modify_PC] <= choice ? 2'b11 : 2'b01;
                    2'b11 : counter[modify_PC] <= choice ? 2'b11 : 2'b10;
                endcase
            end
        end
    end
    */
    
    //--------------------gshared
     localparam table_size = 64;
     reg    [1 : 0] counter[table_size - 1 : 0];
     reg         [`indexWidth - 1 : 0] gh;
     reg         [`indexWidth - 1 : 0] ghb;
     assign predict1 = counter[gh ^ PC1[`indexWidth + 1 : 2]][1];
     assign predict2 = counter[gh ^ PC2[`indexWidth + 1 : 2]][1];
      
     integer i;
     always @ (posedge clk) begin
         if (rst) begin
             for (i = 0; i < table_size; i = i + 1)
                counter[i] <= 2'b00;
             gh <= 0;
             ghb <= 0;
         end else if (rdy) begin
             if (modify_en) begin
                 if (clear) gh <= (ghb << 1) | choice;
                 ghb <= (ghb << 1) | choice;
                 case (counter[ghb ^ modify_PC])
                     2'b00 : counter[ghb ^ modify_PC] <= choice ? 2'b01 : 2'b00;
                     2'b01 : counter[ghb ^ modify_PC] <= choice ? 2'b10 : 2'b00;
                     2'b10 : counter[ghb ^ modify_PC] <= choice ? 2'b11 : 2'b01;
                     2'b11 : counter[ghb ^ modify_PC] <= choice ? 2'b11 : 2'b10;
                 endcase
             end
             if (insert_en && !clear) begin
                 gh       <= (gh << 1) | (mux ? predict2 : predict1);
             end
         end
     end
endmodule
