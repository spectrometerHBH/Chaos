# Chaos
ACM Class CPU project


## RISCV32I Instruction Set 

0 - unsupported
1 - waiting for test
2 - complete

### Integer Computational Insturctions
1. **Integer R-I Instructions**   

    [1] ADDI  

    [1] SLTI	(set less than imm)  

    [1] SLTIU  

    [1] XORI  

    [1] ORI  

    [1] ANDI  

    [1] SLLI	(logical left shift)  

    [1] SRLI	(logical right shift)  

    [1] SRAI	(arthmetic right shift)  

    [0] LUI	    (load upper imm)  

    [0] AUIPC	(add  upper imm to PC)

2. **Integer R-R Instructions**  

    [1] ADD  

    [1] SUB  

    [1] SLT()  

    [1] SLTU  

    [1] XOR  

    [1] SLL	(logical left shift)  

    [1] SRL      (logical right shift)  

    [1] SRA	(arthmetic right shift)  

    [1] OR  

    [1] AND

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
