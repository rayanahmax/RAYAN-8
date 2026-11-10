; RAYAN-8 Phase 8 experiment: Fibonacci.
; Computes fib(10) = 55 into R0.
; Iterative: a=0, b=1, repeat { next=a+b; a=b; b=next }.
; RAM[0] is scratch used to swap, since we have only four registers.
; The loop uses the borrow-exit pattern (the ISA has no jump-if-not-zero).
; Counter R2 = 9 gives 10 iterations, so R0 = fib(10).
        LDI   R0, 0        ; a = fib(0)
        LDI   R1, 1        ; b = fib(1)
        LDI   R2, 9        ; counter = iterations - 1
        LDI   R3, 1        ; step = 1
loop:   ADD   R0, R1       ; R0 = next = a + b
        STORE R0, 0        ; RAM[0] = next
        MOV   R0, R1       ; a = b
        LOAD  R1, 0        ; b = next
        SUB   R2, R3       ; counter -= 1
        JC    done         ; exit when the counter borrows (ran 10 times)
        JMP   loop
done:   HALT
