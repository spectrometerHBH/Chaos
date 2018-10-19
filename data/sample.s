.org 0x0
.global _start

_start:

    ori  x1,x0,0x80             # x1 = 0x80
    slli  x1,x1,16              # x1 = 0x800000
    ori  x1,x1,0x10             # x1 = 0x800010

    ori  x2,x0,0x80             # x2 = 0x80
    slli  x2,x2,16              # x2 = 0x800000
    ori  x2,x2,0x01             # x2 = 0x800001

    add  x3,x2,x1               # x3 = 0x1000011

    sub  x3,x1,x0               # x3 = 0x800010
    ori  x3,x0,0xf              # x3 = 0xf

    addi x3,x3,2                # x3 = 0x11
    srli x3,x3,1                # x3 = 0x8
