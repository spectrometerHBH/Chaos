# Chaos
ACM Class CPU project

## Feature
 Feature | RISC-V CPU(version1, final version)
--- | ---
ISA | RISCV(RV32I subset) 
CLOCK RATE | 100MHz 
Pipelining | 3 stages(Fetch, Decode, Execution)  
Dynamic Scheduling | Tomasulo Algorithm
Superscalar | Multiple issues & FUs(2 issues per clock at most)
Cache | 512B 2-way set associative I-cache
Memory | 128K BRAM on chip

Feature | RISC-V CPU(version2, slower than version1)
--- | ---
ISA | RISCV(RV32I subset) 
CLOLK RATE | 50MHz
Pipelining | 5 stages(Fetch, Decode, Dispatch, Execution, Commit)  
Dynamic Scheduling | Tomasulo Algorithm
Superscalar | Multiple issues & FUs(2 issues per clock at most)
Dynamic Speculation | 64-entry gshared Predictor
Cache | 512B 2-way set associative I-cache
Memory | 128K BRAM on chip

Both versions pass all tests on FPGA(xc7a35tcpg236-1)

## RISCV32I Instruction Set 
0 - unsupported  
1 - waiting for test  
2 - pass simulation  
3 - complete  

### Integer Computational Insturctions
1. **Integer R-I Instructions**   
    [3] ADDI  
    [3] SLTI	(set less than imm)  
    [3] SLTIU  
    [3] XORI  
    [3] ORI  
    [3] ANDI  
    [3] SLLI	(logical left shift)  
    [3] SRLI	(logical right shift)  
    [3] SRAI	(arthmetic right shift)  
    [3] LUI	    (load upper imm)  
    [3] AUIPC	(add  upper imm to PC)

2. **Integer R-R Instructions**  
    [3] ADD  
    [3] SUB  
    [3] SLT  
    [3] SLTU  
    [3] XOR  
    [3] SLL	(logical left shift)  
    [3] SRL      (logical right shift)  
    [3] SRA	(arthmetic right shift)  
    [3] OR  
    [3] AND

3. **Nop Instructions**

### Control Transfer Instructions
1. **Unconditional Jumps**  
    [3] JAL  
  	[3] JALR  

2. **Conditional Branches**  
	[3] BEQ  
	[3] BNE  
	[3] BLT  
	[3] BGE  
	[3] BLTU  
	[3] BGEU  

### Load & Store Instructions
1. **Load**  
	[3] LB  
	[3] LH  
	[3] LW  
	[3] LBU  
	[3] LHU  
	
2. **Save**  
	[3] SB  
	[3] SH  
	[3] SW  

## Testcases
0 - failed  
1 - passed  
2 - unknown  
[1] array_test1  
[1] array_test2  
[1] basicopt1  
[1] bulgarian  
[1] expr  
[1] gcd  
[1] hanoi  
[1] lvalue2  
[1] magic  
[1] manyarguments  
[1] multiarray  
[1] pi  
[1] qsort  
[1] queens  
[1] statement_test  
[1] superloop  
[1] tak  
