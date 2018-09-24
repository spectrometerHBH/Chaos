`ifndef __DEFINES__
`define __DEFINES__

`define classOpWidth    7
`define classOp2Width   3
`define classOp3Width   7
`define tagWidth        3
`define dataWidth       32
`define instWidth       32
`define regWidth        5
`define RSsize          4
`define RIImmWidth      12
`define regCnt          32

`define classOpRange    6  : 0  
`define classOp2Range   14 : 12
`define classOp3Range   31 : 25
`define rdRange         11 : 7
`define rs1Range        19 : 15   
`define rs2Range        24 : 20
`define ImmRange        31 : 20

`define tagFree     4'b1000
`define classLUI    7'b0110111
`define classAUIPC  7'b0010111
`define classJAL    7'b1101111
`define classJALR   7'b1100111
`define classBranch 7'b1100011
`define classLoad   7'b0000011
`define classSave   7'b0100011
`define classRI     7'b0010011
`define classRR     7'b0110011
`define nopinstr    32'b00000000000000000000000000110011

//new opcode for conveinience
`define newopWidth     5 
`define LUI     5'b00000
`define AUIPC   5'b00001
`define JAL     5'b00010
`define JALR    5'b00011
`define BEQ     5'b00100
`define BNE     5'b00101    
`define BLT     5'b00110     
`define BGE     5'b00111     
`define BLTU    5'b01000     
`define BGEU    5'b01001     
`define LB      5'b01010     
`define LH      5'b01011    
`define LW      5'b01100    
`define LBU     5'b01101    
`define LHU     5'b01110    
`define SB      5'b01111    
`define SW      5'b10000    
`define SH      5'b10001    
`define ADD     5'b10010    
`define SUB     5'b10011
`define SLL     5'b10100   
`define SLT     5'b10101   
`define SLTU    5'b10110   
`define XOR     5'b10111    
`define SRL     5'b11000
`define SRA     5'b11001
`define OR      5'b11010   
`define AND     5'b11011   
`define NOP     5'b11100

`endif