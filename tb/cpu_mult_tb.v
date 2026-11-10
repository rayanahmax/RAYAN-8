// Phase 8 experiment: multiplication by repeated addition.
// Assembles nothing here; loads mult.hex (produced by the assembler from
// mult.asm) and checks that R2 = 7 * 5 = 35.
`timescale 1ns/1ps
module cpu_mult_tb;
    reg clk = 0;
    reg reset;
    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/mult.hex")) dut (.clk(clk), .reset(reset));

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
        $dumpfile("build/cpu_mult.vcd");
        $dumpvars(0, cpu_mult_tb);

        reset = 1;
        @(negedge clk); @(negedge clk);
        reset = 0;

        for (i = 0; i < 400 && dut.halt !== 1'b1; i = i + 1)
            @(posedge clk);
        #1;
        $display("CYCLES = %0d", i);

        check8(dut.halt === 1'b1 ? 8'd1 : 8'd0, 8'd1,  "halted");
        check8(dut.u_rf.regs[2], 8'd35,  "R2 = 35 (7 * 5)");
        check8(dut.u_rf.regs[0], 8'd7,   "R0 = 7");
        check8(dut.u_rf.regs[3], 8'd1,   "R3 = 1");
        check8(dut.u_rf.regs[1], 8'd255, "R1 = 255 (counter underflowed to exit)");

        if (errors == 0)
            $display("ALL %0d MULT TESTS PASSED", checks);
        else
            $display("%0d of %0d MULT TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
