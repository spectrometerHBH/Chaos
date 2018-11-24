# Chaos
ACM Class CPU project


## RISCV32I Instruction Set 

0 - unsupported

1 - waiting for test

2 - pass simulation

3 - complete

### Integer Computational Insturctions
1. **Integer R-I Instructions**   

    [2] ADDI  

    [2] SLTI	(set less than imm)  

    [2] SLTIU  

    [2] XORI  

    [2] ORI  

    [2] ANDI  

    [2] SLLI	(logical left shift)  

    [2] SRLI	(logical right shift)  

    [2] SRAI	(arthmetic right shift)  

    [2] LUI	    (load upper imm)  

    [2] AUIPC	(add  upper imm to PC)

2. **Integer R-R Instructions**  

    [2] ADD  

    [2] SUB  

    [2] SLT  

    [2] SLTU  

    [2] XOR  

    [2] SLL	(logical left shift)  

    [2] SRL      (logical right shift)  

    [2] SRA	(arthmetic right shift)  

    [2] OR  

    [2] AND

3. **Nop Instructions**

### Control Transfer Instructions
1. **Unconditional Jumps**  
    
    [2] JAL  

  	[2] JALR  

2. **Conditional Branches**  
	
	[2] BEQ  
	
	[2] BNE  
	
	[2] BLT  
	
	[2] BGE  
	
	[2] BLTU  
	
	[2] BGEU  
	

### Load & Store Instructions
1. **Load**  
	
	[2] LB  
	
	[2] LH  
	
	[2] LW  
	
	[2] LBU  
	
	[2] LHU  
	
2. **Save**  
	
	[2] SB  
	
	[2] SH  

	[2] SW  

## Testcases
0 - failed  

1 - passed  

2 - unknown

    [1] array_test1  

    [0] array_test2  

    [1] basicopt1  

    [0] bulgarian  

    [1] expr  

    [1] gcd  

    [1] hanoi  

    [1] lvalue2  

    [1] magic  

    [1] manyarguments  

    [0] multiarray  

    [1] pi  

    [2] qsort  

    [0] queens  

    [1] statement_test  

    [1] superloop  

    [1] tak  


## Tomasulo
Tomasulo with ROB, but without speculation
