.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000
.equ C_Q7, 91

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE
    MOVI R6, #C_Q7

; V46 Core1 receives raw Stage1 operands through shared RAM,
; computes the lower halves for RAM10/11/14/15, then continues
; with the V45 Stage2/Stage3 responsibilities.
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

; Core1 Stage 1 lower half: DIF butterfly(1, 5, W1) -> RAM10/11
    LDR R8, [R0 + 20]
    LDR R9, [R0 + 21]
    LDR R10, [R0 + 22]
    LDR R11, [R0 + 23]
    SUB R2, R8, R10
    SUB R3, R9, R11
    ADD R4, R2, R3
    MUL R4, R4, R6
    SUB R14, R3, R2
    MUL R14, R14, R6
    STR R4, [R0 + 10]
    STR R14, [R0 + 11]

; Core1 Stage 1 lower half: DIF butterfly(3, 7, W3) -> RAM14/15
    LDR R8, [R0 + 24]
    LDR R9, [R0 + 25]
    LDR R10, [R0 + 26]
    LDR R11, [R0 + 27]
    SUB R2, R8, R10
    SUB R3, R9, R11
    SUB R4, R3, R2
    MUL R4, R4, R6
    ADD R14, R2, R3
    SUB R14, R0, R14
    MUL R14, R14, R6
    STR R4, [R0 + 14]
    STR R14, [R0 + 15]

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

; Core1 Stage 3 half.

; Stage 3: DIF butterfly(4, 5, W0)
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

; Stage 3: DIF butterfly(6, 7, W0), delayed final addr15 write
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
    STR R3, [R5 + 15]

    HALT
