; RAYAN-8 Phase 8 experiment: maximum value in an array.
;
; ISA limitation: memory uses direct addressing only (LOAD/STORE take an 8-bit
; immediate address), so a loop cannot index RAM with a register. We therefore
; UNROLL the scan over a fixed 5-element array. This is a documented finding,
; not a bug: indexed addressing would be a v1.1 extension.
;
; Array [3, 42, 17, 8, 25] is written to RAM[10..14], then scanned.
; Result (max) ends in R0 = 42.
;
; Compare trick: SUB max, value sets Carry when value > max (a borrow),
; so JC updates the max. A scratch register R2 holds the subtraction so
; the running max in R0 is not destroyed.

        LDI   R1, 3
        STORE R1, 10        ; RAM[10] = 3
        LDI   R1, 42
        STORE R1, 11        ; RAM[11] = 42
        LDI   R1, 17
        STORE R1, 12        ; RAM[12] = 17
        LDI   R1, 8
        STORE R1, 13        ; RAM[13] = 8
        LDI   R1, 25
        STORE R1, 14        ; RAM[14] = 25

        LOAD  R0, 10        ; max = arr[0]

        LOAD  R1, 11        ; value = arr[1]
        MOV   R2, R0        ; scratch = max
        SUB   R2, R1        ; max - value, Carry if value > max
        JC    u1
        JMP   s1
u1:     MOV   R0, R1        ; max = value
s1:     LOAD  R1, 12
        MOV   R2, R0
        SUB   R2, R1
        JC    u2
        JMP   s2
u2:     MOV   R0, R1
s2:     LOAD  R1, 13
        MOV   R2, R0
        SUB   R2, R1
        JC    u3
        JMP   s3
u3:     MOV   R0, R1
s3:     LOAD  R1, 14
        MOV   R2, R0
        SUB   R2, R1
        JC    u4
        JMP   s4
u4:     MOV   R0, R1
s4:     HALT
