// Testbench for the RAYAN-8 Program Counter.
`timescale 1ns/1ps
module pc_tb;
    reg        clk = 0;
    reg        reset, en;
    reg  [7:0] d;
    wire [7:0] q;

    integer errors = 0;
    integer checks = 0;

    pc dut (.clk(clk), .reset(reset), .en(en), .d(d), .q(q));

    always #5 clk = ~clk;

    task step(input rst, input e, input [7:0] dd);
        begin
            @(negedge clk);
            reset = rst; en = e; d = dd;
            @(negedge clk);   // posedge in between captured
        end
    endtask

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
        $dumpfile("build/pc.vcd");
        $dumpvars(0, pc_tb);

        reset = 1; en = 0; d = 0;
        step(1, 0, 8'd0);   check8(q, 8'd0,  "reset -> 0");
        step(0, 1, 8'd5);   check8(q, 8'd5,  "load 5");
        step(0, 0, 8'd9);   check8(q, 8'd5,  "en=0 holds 5");
        step(0, 1, 8'd10);  check8(q, 8'd10, "load 10");
        step(1, 1, 8'd0);   check8(q, 8'd0,  "reset wins over en");

        if (errors == 0)
            $display("ALL %0d PC TESTS PASSED", checks);
        else
            $display("%0d of %0d PC TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
