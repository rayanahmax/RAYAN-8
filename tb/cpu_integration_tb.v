// Phase 7 hardware-software integration test.
// Loads machine code produced by the C++ assembler (integration.hex,
// assembled from integration.asm) into the CPU and checks the final state.
`timescale 1ns/1ps
module cpu_integration_tb;
    reg clk = 0;
    reg reset;
    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/integration.hex")) dut (
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
        $dumpfile("build/cpu_integration.vcd");
        $dumpvars(0, cpu_integration_tb);

        reset = 1;
        @(negedge clk); @(negedge clk);
        reset = 0;

        for (i = 0; i < 200 && dut.halt !== 1'b1; i = i + 1)
            @(posedge clk);
        #1;

        check8(dut.halt === 1'b1 ? 8'd1 : 8'd0, 8'd1, "halted");
        check8(dut.u_rf.regs[0], 8'd30,  "R0 = 30");
        check8(dut.u_rf.regs[1], 8'd30,  "R1 = 30 (MOV after taken branch)");
        check8(dut.u_rf.regs[2], 8'd0,   "R2 = 0 (SUB, Z set)");
        check8(dut.u_rf.regs[3], 8'd0,   "R3 = 0 (LDI 99 skipped by JZ)");
        check8(dut.u_dmem.mem[100], 8'd30, "RAM[100] = 30 (STORE/LOAD round trip)");

        if (errors == 0)
            $display("ALL %0d INTEGRATION CHECKS PASSED", checks);
        else
            $display("%0d of %0d INTEGRATION CHECKS FAILED", errors, checks);
        $finish;
    end
endmodule
