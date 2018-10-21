TOOL_CHAIN = /opt/riscv/bin
CROSS_COMPILE = $(TOOL_CHAIN)/riscv32-unknown-elf-
 
%.o: %.s 
	/opt/riscv/bin/riscv32-unknown-elf-as $< -o $@ -march=rv32i -mabi=ilp32
%.om: %.o
 
	$(CROSS_COMPILE)ld $< -o $@
%.bin: %.om
 
	$(CROSS_COMPILE)objcopy -O binary $<  $@
%.data: %.bin
 
	python bin2ascii.py $< $@
	rm -f *.bin *.om *.o
clean:
	rm -f *.o *.om *.bin *.data
