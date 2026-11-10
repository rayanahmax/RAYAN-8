// Testbench for the RAYAN-8 CPU datapath.
// Runs a small program (LDI, ADD, SUB, STORE, LOAD, HALT) and checks
// the final register and data-memory contents.
`timescale 1ns/1ps
module cpu_tb;
    reg clk = 0;
    reg reset;

    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/test1.hex")) dut (
        .clk(clk), .reset(reset)
    );

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
        $dumpfile("build/cpu.vcd");
        $dumpvars(0, cpu_tb);

        reset = 1;
        @(negedge clk);
        @(negedge clk);
        reset = 0;

        // Run until the CPU halts, with a timeout.
        for (i = 0; i < 200 && dut.halt !== 1'b1; i = i + 1)
            @(posedge clk);

        #1;
        $display("CYCLES = %0d", i);
        check8(dut.halt === 1'b1 ? 8'd1 : 8'd0, 8'd1, "CPU reached HALT");
        check8(dut.u_rf.regs[0], 8'd42, "R0 = 42");
        check8(dut.u_rf.regs[1], 8'd22, "R1 = 22");
        check8(dut.u_rf.regs[2], 8'd42, "R2 = 42");
        check8(dut.u_rf.regs[3], 8'd0,  "R3 = 0");
        check8(dut.u_dmem.mem[20], 8'd42, "RAM[20] = 42");

        if (errors == 0)
            $display("ALL %0d CPU TESTS PASSED", checks);
        else
            $display("%0d of %0d CPU TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
