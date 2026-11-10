// Phase 5 ISA regression. Runs six small programs through the real CPU,
// one per opcode class, and checks final register state.
`timescale 1ns/1ps
module cpu_isa_tb;
    reg clk = 0;
    reg reset;
    integer i;
    integer errors = 0;
    integer checks = 0;

    cpu #(.INIT_FILE("tests/programs/arith.hex")) dut_arith(.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/logic.hex")) dut_logic(.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/mov.hex"))   dut_mov  (.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/jmp.hex"))   dut_jmp  (.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/jz.hex"))    dut_jz   (.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/jc.hex"))    dut_jc   (.clk(clk), .reset(reset));
    cpu #(.INIT_FILE("tests/programs/jz_notaken.hex")) dut_jznt (.clk(clk), .reset(reset));

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

    task checkhalt(input h, input [511:0] name);
        begin
            checks = checks + 1;
            if (h !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL %0s: did not halt", name);
            end else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("build/cpu_isa.vcd");
        $dumpvars(0, cpu_isa_tb);

        reset = 1;
        @(negedge clk); @(negedge clk);
        reset = 0;

        for (i = 0; i < 150 &&
             !(dut_arith.halt && dut_logic.halt && dut_mov.halt &&
               dut_jmp.halt && dut_jz.halt && dut_jc.halt && dut_jznt.halt); i = i + 1)
            @(posedge clk);
        #1;
        $display("CYCLES = %0d (until all halted)", i);

        // Arithmetic: ADD then SUB
        checkhalt(dut_arith.halt, "arith halted");
        check8(dut_arith.u_rf.regs[0], 8'd50, "arith R0 = 50");
        check8(dut_arith.u_rf.regs[1], 8'd20, "arith R1 = 20");

        // Logic: AND, OR, XOR, NOT
        checkhalt(dut_logic.halt, "logic halted");
        check8(dut_logic.u_rf.regs[0], 8'h00, "logic R0 = 00 (AND)");
        check8(dut_logic.u_rf.regs[1], 8'hF3, "logic R1 = F3 (NOT)");
        check8(dut_logic.u_rf.regs[2], 8'h33, "logic R2 = 33 (OR+XOR)");
        check8(dut_logic.u_rf.regs[3], 8'h30, "logic R3 = 30");

        // MOV
        checkhalt(dut_mov.halt, "mov halted");
        check8(dut_mov.u_rf.regs[1], 8'd77, "mov R1 = 77");

        // JMP skips the LDI R0,99 at address 2
        checkhalt(dut_jmp.halt, "jmp halted");
        check8(dut_jmp.u_rf.regs[0], 8'd1,  "jmp R0 = 1 (skipped 99)");
        check8(dut_jmp.u_rf.regs[1], 8'd2,  "jmp R1 = 2");

        // JZ taken: SUB made Z=1, so LDI R2,99 at address 4 is skipped
        checkhalt(dut_jz.halt, "jz halted");
        check8(dut_jz.u_rf.regs[0], 8'd0,   "jz R0 = 0");
        check8(dut_jz.u_rf.regs[2], 8'd0,   "jz R2 = 0 (skipped 99)");
        check8(dut_jz.u_rf.regs[3], 8'd7,   "jz R3 = 7");

        // JC taken: SUB 3-5 set C, so LDI R2,99 at address 4 is skipped
        checkhalt(dut_jc.halt, "jc halted");
        check8(dut_jc.u_rf.regs[0], 8'd254, "jc R0 = 254");
        check8(dut_jc.u_rf.regs[2], 8'd0,   "jc R2 = 0 (skipped 99)");
        check8(dut_jc.u_rf.regs[3], 8'd8,   "jc R3 = 8");

        // JZ not taken: SUB 5-3 leaves Z=0, so the fall-through LDI R2,1 executes
        checkhalt(dut_jznt.halt, "jz not-taken halted");
        check8(dut_jznt.u_rf.regs[0], 8'd2, "jznt R0 = 2");
        check8(dut_jznt.u_rf.regs[2], 8'd1, "jznt R2 = 1 (fell through)");

        if (errors == 0)
            $display("ALL %0d ISA CHECKS PASSED", checks);
        else
            $display("%0d of %0d ISA CHECKS FAILED", errors, checks);
        $finish;
    end
endmodule
