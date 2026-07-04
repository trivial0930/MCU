.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000
.equ C_Q15, 23170

start:
    MOVI R0, #RAM_BASE
    MOVI R1, #0
    MOVI R6, #C_Q15
    MOVI R7, #TEST_BASE

    LDR R2, [R7 + 0]
    STR R2, [R0 + 0]
    LDR R2, [R7 + 1]
    STR R2, [R0 + 1]
    LDR R2, [R7 + 2]
    STR R2, [R0 + 2]
    LDR R2, [R7 + 3]
    STR R2, [R0 + 3]
    LDR R2, [R7 + 4]
    STR R2, [R0 + 4]
    LDR R2, [R7 + 5]
    STR R2, [R0 + 5]
    LDR R2, [R7 + 6]
    STR R2, [R0 + 6]
    LDR R2, [R7 + 7]
    STR R2, [R0 + 7]
    LDR R2, [R7 + 8]
    STR R2, [R0 + 8]
    LDR R2, [R7 + 9]
    STR R2, [R0 + 9]
    LDR R2, [R7 + 10]
    STR R2, [R0 + 10]
    LDR R2, [R7 + 11]
    STR R2, [R0 + 11]
    LDR R2, [R7 + 12]
    STR R2, [R0 + 12]
    LDR R2, [R7 + 13]
    STR R2, [R0 + 13]
    LDR R2, [R7 + 14]
    STR R2, [R0 + 14]
    LDR R2, [R7 + 15]
    STR R2, [R0 + 15]

; Stage 1: butterfly(0, 4, W0)
    LDR R8, [R0 + 0]
    LDR R9, [R0 + 1]
    LDR R10, [R0 + 8]
    LDR R11, [R0 + 9]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 0]
    STR R13, [R0 + 1]
    STR R2, [R0 + 8]
    STR R3, [R0 + 9]

; Stage 1: butterfly(1, 5, W1)
    LDR R8, [R0 + 2]
    LDR R9, [R0 + 3]
    LDR R10, [R0 + 10]
    LDR R11, [R0 + 11]
    ADD R2, R10, R11
    MUL R12, R2, R6
    SUB R3, R11, R10
    MUL R13, R3, R6
    ADD R2, R8, R12
    ADD R3, R9, R13
    SUB R4, R8, R12
    SUB R5, R9, R13
    STR R2, [R0 + 2]
    STR R3, [R0 + 3]
    STR R4, [R0 + 10]
    STR R5, [R0 + 11]

; Stage 1: butterfly(2, 6, W2)
    LDR R8, [R0 + 4]
    LDR R9, [R0 + 5]
    LDR R10, [R0 + 12]
    LDR R11, [R0 + 13]
    MOVR R12, R11
    SUB R13, R1, R10
    ADD R2, R8, R12
    ADD R3, R9, R13
    SUB R4, R8, R12
    SUB R5, R9, R13
    STR R2, [R0 + 4]
    STR R3, [R0 + 5]
    STR R4, [R0 + 12]
    STR R5, [R0 + 13]

; Stage 1: butterfly(3, 7, W3)
    LDR R8, [R0 + 6]
    LDR R9, [R0 + 7]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    SUB R2, R11, R10
    MUL R12, R2, R6
    ADD R3, R10, R11
    SUB R3, R1, R3
    MUL R13, R3, R6
    ADD R2, R8, R12
    ADD R3, R9, R13
    SUB R4, R8, R12
    SUB R5, R9, R13
    STR R2, [R0 + 6]
    STR R3, [R0 + 7]
    STR R4, [R0 + 14]
    STR R5, [R0 + 15]

; Stage 2: butterfly(0, 2, W0)
    LDR R8, [R0 + 0]
    LDR R9, [R0 + 1]
    LDR R10, [R0 + 4]
    LDR R11, [R0 + 5]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 0]
    STR R13, [R0 + 1]
    STR R2, [R0 + 4]
    STR R3, [R0 + 5]

; Stage 2: butterfly(1, 3, W2)
    LDR R8, [R0 + 2]
    LDR R9, [R0 + 3]
    LDR R10, [R0 + 6]
    LDR R11, [R0 + 7]
    MOVR R12, R11
    SUB R13, R1, R10
    ADD R2, R8, R12
    ADD R3, R9, R13
    SUB R4, R8, R12
    SUB R5, R9, R13
    STR R2, [R0 + 2]
    STR R3, [R0 + 3]
    STR R4, [R0 + 6]
    STR R5, [R0 + 7]

; Stage 2: butterfly(4, 6, W0)
    LDR R8, [R0 + 8]
    LDR R9, [R0 + 9]
    LDR R10, [R0 + 12]
    LDR R11, [R0 + 13]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 8]
    STR R13, [R0 + 9]
    STR R2, [R0 + 12]
    STR R3, [R0 + 13]

; Stage 2: butterfly(5, 7, W2)
    LDR R8, [R0 + 10]
    LDR R9, [R0 + 11]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    MOVR R12, R11
    SUB R13, R1, R10
    ADD R2, R8, R12
    ADD R3, R9, R13
    SUB R4, R8, R12
    SUB R5, R9, R13
    STR R2, [R0 + 10]
    STR R3, [R0 + 11]
    STR R4, [R0 + 14]
    STR R5, [R0 + 15]

; Stage 3: butterfly(0, 1, W0)
    LDR R8, [R0 + 0]
    LDR R9, [R0 + 1]
    LDR R10, [R0 + 2]
    LDR R11, [R0 + 3]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 0]
    STR R13, [R0 + 1]
    STR R2, [R0 + 2]
    STR R3, [R0 + 3]

; Stage 3: butterfly(2, 3, W0)
    LDR R8, [R0 + 4]
    LDR R9, [R0 + 5]
    LDR R10, [R0 + 6]
    LDR R11, [R0 + 7]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 4]
    STR R13, [R0 + 5]
    STR R2, [R0 + 6]
    STR R3, [R0 + 7]

; Stage 3: butterfly(4, 5, W0)
    LDR R8, [R0 + 8]
    LDR R9, [R0 + 9]
    LDR R10, [R0 + 10]
    LDR R11, [R0 + 11]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 8]
    STR R13, [R0 + 9]
    STR R2, [R0 + 10]
    STR R3, [R0 + 11]

; Stage 3: butterfly(6, 7, W0)
    LDR R8, [R0 + 12]
    LDR R9, [R0 + 13]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 12]
    STR R13, [R0 + 13]
    STR R2, [R0 + 14]
    STR R3, [R0 + 15]

; Write natural-order FFT output to external verify_RAM.
    MOVI R5, #VERIFY_BASE
    LDR R2, [R0 + 0]
    STR R2, [R5 + 0]
    LDR R2, [R0 + 1]
    STR R2, [R5 + 1]
    LDR R2, [R0 + 8]
    STR R2, [R5 + 2]
    LDR R2, [R0 + 9]
    STR R2, [R5 + 3]
    LDR R2, [R0 + 4]
    STR R2, [R5 + 4]
    LDR R2, [R0 + 5]
    STR R2, [R5 + 5]
    LDR R2, [R0 + 12]
    STR R2, [R5 + 6]
    LDR R2, [R0 + 13]
    STR R2, [R5 + 7]
    LDR R2, [R0 + 2]
    STR R2, [R5 + 8]
    LDR R2, [R0 + 3]
    STR R2, [R5 + 9]
    LDR R2, [R0 + 10]
    STR R2, [R5 + 10]
    LDR R2, [R0 + 11]
    STR R2, [R5 + 11]
    LDR R2, [R0 + 6]
    STR R2, [R5 + 12]
    LDR R2, [R0 + 7]
    STR R2, [R5 + 13]
    LDR R2, [R0 + 14]
    STR R2, [R5 + 14]
    LDR R2, [R0 + 15]
    STR R2, [R5 + 15]

    HALT
