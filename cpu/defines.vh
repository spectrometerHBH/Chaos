`ifndef __DEFINES__
`define __DEFINES__

`define classOpWidth       7
`define classOp2Width      3
`define classOp3Width      7
`define tagWidth           4
`define dataWidth          32
`define instWidth          32
`define addrWidth          32
`define regWidth           5 
`define RIImmWidth         12
`define UImmWidth          20
`define JImmWidth          20
`define newopWidth         5 
`define rw_flagWidth       2
`define maskWidth          4

`define rs_alu_size        4
`define rs_alu_sel         2
`define rs_branch_size     2
`define rs_branch_sel      1 
`define lsbuf_size         4
`define lsbuf_sel          2 
`define reg_size           32
`define rob_size           8
`define rob_sel            3
`define ram_data_bus_width 8

`define classOpRange    6  : 0  
`define classOp2Range   14 : 12
`define classOp3Range   31 : 25
`define rdRange         11 : 7
`define rs1Range        19 : 15   
`define rs2Range        24 : 20
`define ImmRange        31 : 20
`define UImmRange       31 : 12

`define aluWidth          80
`define aluOpRange        4  : 0
`define aluData1Range     36 : 5
`define aluTag1Range      40 : 37
`define aluData2Range     72 : 41
`define aluData2Low5Range 45 : 41 
`define aluTag2Range      76 : 73
`define aluDestRange      79 : 77

`define branchWidth        109
`define branchOpRange      4   : 0
`define branchData1Range   36  : 5
`define branchTag1Range    40  : 37
`define branchData2Range   72  : 41
`define branchTag2Range    76  : 73
`define branchOffsetRange  108 : 77

`define lsWidth         112
`define lsOpRange       4 : 0
`define lsBaseRange     36 : 5 
`define lsBaseTagRange  40 : 37 
`define lsSrcRange      72 : 41    
`define lsSrcTagRange   76 : 73
`define lsImmRange      108 : 77
`define lsDestRange     111 : 109

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

`define NOP    5'b00000
`define LUI    5'b00001
`define AUIPC  5'b00010
`define JAL    5'b00011
`define JALR   5'b00100
`define BEQ    5'b00101    
`define BNE    5'b00110     
`define BLT    5'b00111     
`define BGE    5'b01000     
`define BLTU   5'b01001     
`define BGEU   5'b01010     
`define LB     5'b01011    
`define LH     5'b01100    
`define LW     5'b01101    
`define LBU    5'b01110    
`define LHU    5'b01111    
`define SB     5'b10000    
`define SW     5'b10001    
`define SH     5'b10010    
`define ADD    5'b10011
`define SUB    5'b10100   
`define SLL    5'b10101   
`define SLT    5'b10110   
`define SLTU   5'b10111    
`define XOR    5'b11000
`define SRL    5'b11001
`define SRA    5'b11010   
`define OR     5'b11011   
`define AND    5'b11100

`endif