.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE

; Core3 owns X3/X7 and waits for Core1 Stage2(5,7,W2).
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

; Stage 3 owner butterfly(6, 7, W0)
    LDR R8, [R0 + 12]
    LDR R9, [R0 + 13]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R5 + 3]
    STR R13, [R5 + 11]
    STR R2, [R5 + 7]
    STR R3, [R5 + 15]

    HALT
