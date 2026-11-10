; RAYAN-8 Phase 8 experiment: multiplication by repeated addition.
; Computes R2 = R0 * R1  (7 * 5 = 35).
; Loop trick: our ISA has no "jump if not zero", only JZ and JC.
; We decrement the counter with SUB and exit when it borrows (goes below 0),
; which JC detects via the Carry flag.
        LDI  R0, 7        ; multiplicand a
        LDI  R1, 5        ; multiplier b (also the loop counter)
        LDI  R2, 0        ; accumulator / result
        LDI  R3, 1        ; constant step = 1
loop:   SUB  R1, R3       ; b = b - 1 ; Carry set if this borrowed
        JC   done         ; if b went below 0, we have added a exactly b times
        ADD  R2, R0       ; result += a
        JMP  loop
done:   HALT
