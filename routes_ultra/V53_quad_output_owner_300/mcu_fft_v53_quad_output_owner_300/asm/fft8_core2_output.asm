.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE

; Core2 owns X2/X6 and waits for Core0 Stage2(1,3,W2).
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

; Stage 3 owner butterfly(2, 3, W0)
    LDR R8, [R0 + 4]
    LDR R9, [R0 + 5]
    LDR R10, [R0 + 6]
    LDR R11, [R0 + 7]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R5 + 2]
    STR R13, [R5 + 10]
    STR R2, [R5 + 6]
    STR R3, [R5 + 14]

    HALT
