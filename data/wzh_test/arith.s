.org 0x0
.global _start

_start:
# ================== Test for arithmatic ops ================
	lui	x1, 0x80000		# x1 				= 0x80000000 4
	ori x1, x1, 0x010	# x1 = x1 | 0x010	= 0x80000010 8

	lui x2, 0x80000		# x2				= 0x80000000 c
	ori	x2, x2, 0x001	# x2 = x2 | 0x001	= 0x80000001 10

	add x3, x2, x1		# x3				= 0x00000011 14
	addi x3, x3, 0x0fe	# x3				= 0x0000010f 18
	add x3, x3, x2		# x3				= 0x80000110 1c

	sub x3, x3, x2		# x3 				= 0x0000010f 20

# ================== Test for cmp ops =======================
	lui x1,0xffff0		# x1 				= 0xffff0000 24
	slt x2, x1, x0		# x2				= 1		notice: signed 28
	sltu x2, x1, x0		# x2				= 0		notice: unsigned 2c
	lui x1, 0x00001		# x1				= 0x00001000 30
	slti x3, x1, -0x800	# x3				= 0		notice: signed 34
	sltiu x3, x1, -0x800 # x3				= 1		notice: signed extend and unsigned comparation 38
