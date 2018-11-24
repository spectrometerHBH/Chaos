	.file	"test.c"
	.option nopic
	.text
	.globl	__umodsi3
	.globl	__modsi3
	.globl	__udivsi3
	.globl	__divsi3
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	lui	a5,%hi(pa)
	sw	s3,28(sp)
	lw	a1,%lo(pa)(a5)
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s1,36(sp)
	sw	s2,32(sp)
	sw	s4,24(sp)
	sw	s5,20(sp)
	sw	s6,16(sp)
	li	a5,196608
	li	a4,52
	sb	a4,0(a5)
	li	a4,10
	sb	a4,0(a5)
	li	a5,1
	sw	a5,4(a1)
	li	a5,2
	sw	a5,8(a1)
	li	a5,3
	addi	s3,sp,4
	sw	a5,12(a1)
	li	a5,48
	sb	a5,4(sp)
	sw	zero,0(a1)
	mv	a5,s3
	li	a4,48
	li	a2,196608
	j	.L3
.L18:
	lbu	a4,-1(a5)
	mv	a5,a3
.L3:
	sb	a4,0(a2)
	addi	a3,a5,-1
	bne	s3,a5,.L18
	lw	s2,4(a1)
	li	s6,0
	bgez	s2,.L4
	sub	s2,zero,s2
	li	s6,1
.L4:
	li	s1,0
	li	s5,9
	j	.L5
.L11:
	mv	s1,s4
	mv	s2,a0
.L5:
	li	a1,10
	mv	a0,s2
	call	__modsi3
	addi	a0,a0,48
	addi	s4,s1,1
	andi	s0,a0,0xff
	add	a5,s3,s4
	mv	a0,s2
	li	a1,10
	sb	s0,-1(a5)
	call	__divsi3
	bgt	s2,s5,.L11
	beqz	s6,.L6
	addi	a5,sp,16
	add	a5,a5,s4
	li	a4,45
	sb	a4,-12(a5)
	mv	s1,s4
	li	s0,45
.L6:
	add	a5,s3,s1
	li	a3,196608
	j	.L8
.L19:
	lbu	s0,-1(a5)
	mv	a5,a4
.L8:
	sb	s0,0(a3)
	addi	a4,a5,-1
	bne	s3,a5,.L19
	lui	a5,%hi(.LC0)
	addi	a5,a5,%lo(.LC0)
	li	a4,102
	li	a3,196608
.L9:
	sb	a4,0(a3)
	addi	a5,a5,1
	lbu	a4,0(a5)
	bnez	a4,.L9
	li	a5,10
	sb	a5,0(a3)
	lw	ra,44(sp)
	lw	s0,40(sp)
	lw	s1,36(sp)
	lw	s2,32(sp)
	lw	s3,28(sp)
	lw	s4,24(sp)
	lw	s5,20(sp)
	lw	s6,16(sp)
	li	a0,0
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.globl	pa
	.comm	a,16,4
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"fuck you"
	.section	.sdata,"aw"
	.align	2
	.type	pa, @object
	.size	pa, 4
pa:
	.word	a
	.ident	"GCC: (GNU) 8.2.0"

