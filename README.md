# Chaos
ACM Class CPU project


## RISCV32I Instruction Set 

### Integer Computational Insturctions
1. **Integer R-I Instructions**
    [] ADDI  
    
    [] SLTI	(set less than imm)  
    
    [] SLTIU  
    
    [] XORI  
    
    [] ORI  
    
    [] ANDI  
    
    [] SLLI	(logical left shift)  
    
    [] SRLI	(logical right shift)  
    
    [] SRAI	(arthmetic right shift)  
    
    [] LUI	(load upper imm)  
    
    [] AUIPC	(add upper imm to PC)

2. **Integer R-R Instructions**
    [] ADD  
    
    [] SUB  
    
    [] SLT()  
    
    [] SLTU  
    
    [] XOR  
    
    [] SLL	(logical left shift)  
    
    [] SRL      (logical right shift)  
    
    [] SRA	(arthmetic right shift)  
    
    [] OR  
    
    [] AND
3. **Nop Instructions**

### Control Transfer Instructions
1. **Unconditional Jumps**
	[] JAL  

	[] JALR  
	

2. **Conditional Branches**
	[] BEQ  
	
	[] BNE  
	
	[] BLT  
	
	[] BGE  
	
	[] BLTU  
	
	[] BGEU  
	

### Load & Store Instructions
1. **Load**
	[] LB  
	
	[] LH  
	
	[] LW  
	
	[] LBU  
	
	[] LHU  
	
2. **Save**
	[] SB  
	
	[] SH  

	[] SW  

## Tomasulo
Tomasulo with ROB and speculation
