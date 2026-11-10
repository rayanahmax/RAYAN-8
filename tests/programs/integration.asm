; RAYAN-8 Phase 7 integration program
; Adds two numbers, round-trips through memory, uses a taken branch,
; then moves the result. Final state is fully deterministic.
        LDI  R0, 10       ; R0 = 10
        LDI  R1, 20       ; R1 = 20
        ADD  R0, R1       ; R0 = 30
        STORE R0, 100     ; RAM[100] = 30
        LOAD  R2, 100     ; R2 = 30
        SUB   R2, R0      ; R2 = 0, sets Z
        JZ    equal       ; taken, skips the next LDI
        LDI   R3, 99      ; must NOT execute
equal:  MOV   R1, R0      ; R1 = 30
        HALT
