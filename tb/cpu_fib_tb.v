// Phase 8 experiment: Fibonacci.
// Loads fib.hex (assembled from fib.asm) and checks fib(10) = 55 in R0.
`timescale 1ns/1ps
module cpu_fib_tb;
    reg clk = 0;
    reg reset;
    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/fib.hex")) dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    task check8(input [7:0] got, input [7:0] exp, input [511:0] name);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %0d expected %0d", name, got, exp);
            end else begin
                $display("PASS %0s: %0d", name, got);
            end
        end
    endtask

    initial begin
        $dumpfile("build/cpu_fib.vcd");
        $dumpvars(0, cpu_fib_tb);

        reset = 1;
        @(negedge clk); @(negedge clk);
        reset = 0;

        for (i = 0; i < 600 && dut.halt !== 1'b1; i = i + 1)
            @(posedge clk);
        #1;
        $display("CYCLES = %0d", i);

        check8(dut.halt === 1'b1 ? 8'd1 : 8'd0, 8'd1,  "halted");
        check8(dut.u_rf.regs[0], 8'd55,  "R0 = 55 (fib 10)");
        check8(dut.u_rf.regs[1], 8'd89,  "R1 = 89 (fib 11)");
        check8(dut.u_rf.regs[2], 8'd255, "R2 = 255 (counter underflow)");
        check8(dut.u_rf.regs[3], 8'd1,   "R3 = 1");
        check8(dut.u_dmem.mem[0], 8'd89, "RAM[0] = 89 (scratch swap)");

        if (errors == 0)
            $display("ALL %0d FIB TESTS PASSED", checks);
        else
            $display("%0d of %0d FIB TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
