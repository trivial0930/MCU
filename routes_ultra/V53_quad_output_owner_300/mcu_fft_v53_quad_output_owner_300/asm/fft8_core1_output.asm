.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE

; Core1 computes Stage2 butterfly(5,7,W2) and owns X1/X5.
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

; Core1 Stage 2: DIF butterfly(5, 7, W2)
    LDR R8, [R0 + 10]
    LDR R9, [R0 + 11]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R3, R9, R11
    SUB R14, R10, R8
    STR R12, [R0 + 10]
    STR R13, [R0 + 11]
    STR R3, [R0 + 14]
    STR R14, [R0 + 15]
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

; Stage 3 owner butterfly(4, 5, W0)
    LDR R8, [R0 + 8]
    LDR R9, [R0 + 9]
    LDR R10, [R0 + 10]
    LDR R11, [R0 + 11]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R5 + 1]
    STR R13, [R5 + 9]
    STR R2, [R5 + 5]
    STR R3, [R5 + 13]

    HALT
