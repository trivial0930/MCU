.equ VERIFY_BASE, 0x2000
.equ RAM_BASE, 0x0000

start:
    MOVI R0, #RAM_BASE
    MOVI R5, #VERIFY_BASE

; Core1 waits until Core0 has finished Stage 2, then performs
; the remaining Stage 3 W0 butterflies using ordinary MCU code.
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

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

; Stage 3: DIF butterfly(6, 7, W0)
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
