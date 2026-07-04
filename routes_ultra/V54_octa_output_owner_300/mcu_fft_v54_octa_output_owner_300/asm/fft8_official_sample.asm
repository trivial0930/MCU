.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000
.equ C_Q7, 91

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE
    MOVI R6, #C_Q7
    MOVI R7, #TEST_BASE
    MOVR R12, R0
    MOVR R13, R0

; Core0 owns complex output X0.

; Pair n=0 and n=4, coefficient W(0,0)=(128,0)
    LDR R8, [R7 + 128]
    LDR R9, [R7 + 136]
    LDR R10, [R7 + 132]
    LDR R11, [R7 + 140]
    ADD R8, R8, R10
    ADD R9, R9, R11
    ADD R12, R12, R8
    ADD R13, R13, R9

; Pair n=1 and n=5, coefficient W(1,0)=(128,0)
    LDR R8, [R7 + 129]
    LDR R9, [R7 + 137]
    LDR R10, [R7 + 133]
    LDR R11, [R7 + 141]
    ADD R8, R8, R10
    ADD R9, R9, R11
    ADD R12, R12, R8
    ADD R13, R13, R9

; Pair n=2 and n=6, coefficient W(2,0)=(128,0)
    LDR R8, [R7 + 130]
    LDR R9, [R7 + 138]
    LDR R10, [R7 + 134]
    LDR R11, [R7 + 142]
    ADD R8, R8, R10
    ADD R9, R9, R11
    ADD R12, R12, R8
    ADD R13, R13, R9

; Pair n=3 and n=7, coefficient W(3,0)=(128,0)
    LDR R8, [R7 + 131]
    LDR R9, [R7 + 139]
    LDR R10, [R7 + 135]
    LDR R11, [R7 + 143]
    ADD R8, R8, R10
    ADD R9, R9, R11
    ADD R12, R12, R8
    ADD R13, R13, R9

    STR R12, [R5 + 0]
    STR R13, [R5 + 8]
    HALT
