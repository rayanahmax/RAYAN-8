; Phase 6 assembler test 2: labels and branches
start:
    LDI R0, 5
    LDI R1, 5
    SUB R0, R1
    JZ  done
    LDI R2, 99
done:
    LDI R3, 7
    HALT
