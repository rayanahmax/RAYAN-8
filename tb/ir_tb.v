// Testbench for the RAYAN-8 Instruction Register.
`timescale 1ns/1ps
module ir_tb;
    reg         clk = 0;
    reg         reset, en;
    reg  [15:0] d;
    wire [15:0] q;

    integer errors = 0;
    integer checks = 0;

    ir dut (.clk(clk), .reset(reset), .en(en), .d(d), .q(q));

    always #5 clk = ~clk;

    task step(input rst, input e, input [15:0] dd);
        begin
            @(negedge clk);
            reset = rst; en = e; d = dd;
            @(negedge clk);
        end
    endtask

    task check16(input [15:0] got, input [15:0] exp, input [511:0] name);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %h expected %h", name, got, exp);
            end else begin
                $display("PASS %0s: %h", name, got);
            end
        end
    endtask

    initial begin
        $dumpfile("build/ir.vcd");
        $dumpvars(0, ir_tb);

        reset = 1; en = 0; d = 0;
        step(1, 0, 16'h0000); check16(q, 16'h0000, "reset -> 0");
        step(0, 1, 16'h000F); check16(q, 16'h000F, "load LDI R0,15");
        step(0, 0, 16'hFFFF); check16(q, 16'h000F, "en=0 holds");
        step(0, 1, 16'h9814); check16(q, 16'h9814, "load STORE R2,20");
        step(1, 1, 16'h0000); check16(q, 16'h0000, "reset wins over en");

        if (errors == 0)
            $display("ALL %0d IR TESTS PASSED", checks);
        else
            $display("%0d of %0d IR TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
