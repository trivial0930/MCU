.equ TEST_BASE, 0x1000
.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000
.equ C_Q7, 91

start:
    MOVI R0, #RAM_BASE
    MOVI R1, #0
    MOVI R6, #C_Q7
    MOVI R7, #TEST_BASE
    MOVI R14, #VERIFY_BASE

; Stage 1 reads official FFT input directly from test ROM.
; ext_test_rom_if converts real[128:135]/imag[136:143] Q5 samples to Q12.

; Stage 1: DIF butterfly(0, 4, W0)
    LDR R8, [R7 + 128]
    LDR R9, [R7 + 136]
    LDR R10, [R7 + 132]
    LDR R11, [R7 + 140]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R0 + 0]
    STR R13, [R0 + 1]
    STR R2, [R0 + 8]
    STR R3, [R0 + 9]

; Stage 1: DIF butterfly(1, 5, W1)
    LDR R8, [R7 + 129]
    LDR R9, [R7 + 137]
    LDR R10, [R7 + 133]
    LDR R11, [R7 + 141]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    ADD R4, R2, R3
    MUL R4, R4, R6
    SUB R5, R3, R2
    MUL R5, R5, R6
    STR R12, [R0 + 2]
    STR R13, [R0 + 3]
    STR R4, [R0 + 10]
    STR R5, [R0 + 11]

; Stage 1: DIF butterfly(2, 6, W2)
    LDR R8, [R7 + 130]
    LDR R9, [R7 + 138]
    LDR R10, [R7 + 134]
    LDR R11, [R7 + 142]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    SUB R5, R1, R2
    STR R12, [R0 + 4]
    STR R13, [R0 + 5]
    STR R3, [R0 + 12]
    STR R5, [R0 + 13]

; Stage 1: DIF butterfly(3, 7, W3)
    LDR R8, [R7 + 131]
    LDR R9, [R7 + 139]
    LDR R10, [R7 + 135]
    LDR R11, [R7 + 143]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    SUB R4, R3, R2
    MUL R4, R4, R6
    ADD R5, R2, R3
    SUB R5, R1, R5
    MUL R5, R5, R6
    STR R12, [R0 + 6]
    STR R13, [R0 + 7]
    STR R4, [R0 + 14]
    STR R5, [R0 + 15]

; Stage 2: DIF butterfly(0, 2, W0)
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

; Stage 2: DIF butterfly(1, 3, W2)
    LDR R8, [R0 + 2]
    LDR R9, [R0 + 3]
    LDR R10, [R0 + 6]
    LDR R11, [R0 + 7]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    SUB R5, R1, R2
    STR R12, [R0 + 2]
    STR R13, [R0 + 3]
    STR R3, [R0 + 6]
    STR R5, [R0 + 7]

; Stage 2: DIF butterfly(4, 6, W0)
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

; Stage 2: DIF butterfly(5, 7, W2)
    LDR R8, [R0 + 10]
    LDR R9, [R0 + 11]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    SUB R5, R1, R2
    STR R12, [R0 + 10]
    STR R13, [R0 + 11]
    STR R3, [R0 + 14]
    STR R5, [R0 + 15]

; Stage 3 writes official layout directly to verify RAM.

; Stage 3: DIF butterfly(0, 1, W0)
    LDR R8, [R0 + 0]
    LDR R9, [R0 + 1]
    LDR R10, [R0 + 2]
    LDR R11, [R0 + 3]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R14 + 0]
    STR R13, [R14 + 8]
    STR R2, [R14 + 4]
    STR R3, [R14 + 12]

; Stage 3: DIF butterfly(2, 3, W0)
    LDR R8, [R0 + 4]
    LDR R9, [R0 + 5]
    LDR R10, [R0 + 6]
    LDR R11, [R0 + 7]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R14 + 2]
    STR R13, [R14 + 10]
    STR R2, [R14 + 6]
    STR R3, [R14 + 14]

; Stage 3: DIF butterfly(4, 5, W0)
    LDR R8, [R0 + 8]
    LDR R9, [R0 + 9]
    LDR R10, [R0 + 10]
    LDR R11, [R0 + 11]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R14 + 1]
    STR R13, [R14 + 9]
    STR R2, [R14 + 5]
    STR R3, [R14 + 13]

; Stage 3: DIF butterfly(6, 7, W0)
    LDR R8, [R0 + 12]
    LDR R9, [R0 + 13]
    LDR R10, [R0 + 14]
    LDR R11, [R0 + 15]
    ADD R12, R8, R10
    ADD R13, R9, R11
    SUB R2, R8, R10
    SUB R3, R9, R11
    STR R12, [R14 + 3]
    STR R13, [R14 + 11]
    STR R2, [R14 + 7]
    STR R3, [R14 + 15]

    HALT
