.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000
.equ C_Q7, 91

start:
    MOVI R5, #VERIFY_BASE
    MOVI R7, #TEST_BASE
    MOVI R12, #0
    MOVI R13, #0
    MOVI R0, #0
    MOVI R6, #C_Q7

; Core5 owns complex output X5.

; Pair n=0 and n=4, coefficient W(0,5)=(128,0)
    LDR R8, [R7 + 128]
    LDR R9, [R7 + 136]
    LDR R10, [R7 + 132]
    LDR R11, [R7 + 140]
    SUB R8, R8, R10
    SUB R9, R9, R11
    ADD R12, R12, R8
    ADD R13, R13, R9

; Pair n=1 and n=5, coefficient W(1,5)=(-91,91)
    LDR R8, [R7 + 129]
    LDR R9, [R7 + 137]
    LDR R10, [R7 + 133]
    LDR R11, [R7 + 141]
    SUB R8, R8, R10
    SUB R9, R9, R11
    ADD R14, R8, R9
    SUB R14, R0, R14
    SUB R15, R8, R9

; Pair n=2 and n=6, coefficient W(2,5)=(0,-128)
    LDR R8, [R7 + 130]
    LDR R9, [R7 + 138]
    LDR R10, [R7 + 134]
    LDR R11, [R7 + 142]
    SUB R8, R8, R10
    SUB R9, R9, R11
    ADD R12, R12, R9
    SUB R13, R13, R8

; Pair n=3 and n=7, coefficient W(3,5)=(91,91)
    LDR R8, [R7 + 131]
    LDR R9, [R7 + 139]
    LDR R10, [R7 + 135]
    LDR R11, [R7 + 143]
    SUB R8, R8, R10
    SUB R9, R9, R11
    SUB R10, R8, R9
    ADD R14, R14, R10
    ADD R10, R8, R9
    ADD R15, R15, R10

; Fold all +/-91 terms with two ordinary MUL instructions.
    MUL R14, R14, R6
    ADD R12, R12, R14
    MUL R15, R15, R6
    ADD R13, R13, R15

    STR R12, [R5 + 5]
    STR R13, [R5 + 13]
    HALT
