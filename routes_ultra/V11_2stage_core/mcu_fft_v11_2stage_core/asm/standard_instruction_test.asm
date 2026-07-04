.equ VERIFY_BASE, 0x2000

start:
    MOVI R0, #0
    MOVI R1, #16384
    MOVI R2, #2
    ADD R3, R1, R2
    SUB R4, R1, R2
    AND R5, R1, R2
    OR R6, R1, R2
    MOVR R7, R3
    STR R3, [R0 + 0]
    LDR R8, [R0 + 0]
    CMP R7, R8
    BEQ equal_path
    MOVI R9, #-1
    B finish

equal_path:
    MUL R9, R1, R2
    MOVI R10, #VERIFY_BASE
    STR R3, [R10 + 0]
    STR R4, [R10 + 1]
    STR R5, [R10 + 2]
    STR R6, [R10 + 3]
    STR R7, [R10 + 4]
    STR R8, [R10 + 5]
    STR R9, [R10 + 15]

finish:
    HALT
