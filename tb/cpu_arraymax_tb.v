// Phase 8 experiment: array maximum (unrolled scan).
// Loads arraymax.hex (assembled from arraymax.asm) and checks that R0 = 42,
// the maximum of [3, 42, 17, 8, 25], and that the array is in RAM[10..14].
`timescale 1ns/1ps
module cpu_arraymax_tb;
    reg clk = 0;
    reg reset;
    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/arraymax.hex")) dut (.clk(clk), .reset(reset));

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
        $dumpfile("build/cpu_arraymax.vcd");
        $dumpvars(0, cpu_arraymax_tb);

        reset = 1;
        @(negedge clk); @(negedge clk);
        reset = 0;

        for (i = 0; i < 400 && dut.halt !== 1'b1; i = i + 1)
            @(posedge clk);
        #1;
        $display("CYCLES = %0d", i);

        check8(dut.halt === 1'b1 ? 8'd1 : 8'd0, 8'd1, "halted");
        check8(dut.u_rf.regs[0], 8'd42, "R0 = 42 (maximum)");
        // array as written to data memory
        check8(dut.u_dmem.mem[10], 8'd3,  "RAM[10] = 3");
        check8(dut.u_dmem.mem[11], 8'd42, "RAM[11] = 42");
        check8(dut.u_dmem.mem[12], 8'd17, "RAM[12] = 17");
        check8(dut.u_dmem.mem[13], 8'd8,  "RAM[13] = 8");
        check8(dut.u_dmem.mem[14], 8'd25, "RAM[14] = 25");

        if (errors == 0)
            $display("ALL %0d ARRAYMAX TESTS PASSED", checks);
        else
            $display("%0d of %0d ARRAYMAX TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
