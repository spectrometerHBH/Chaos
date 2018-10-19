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

    [0] AUIPC	(add  upper imm to PC)

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
    
    [0] JAL  

  	[0] JALR  

2. **Conditional Branches**  
	
	[0] BEQ  
	
	[0] BNE  
	
	[0] BLT  
	
	[0] BGE  
	
	[0] BLTU  
	
	[0] BGEU  
	

### Load & Store Instructions
1. **Load**  
	
	[0] LB  
	
	[0] LH  
	
	[0] LW  
	
	[0] LBU  
	
	[0] LHU  
	
2. **Save**  
	
	[0] SB  
	
	[0] SH  

	[0] SW  

## Tomasulo
Tomasulo with ROB and speculation
