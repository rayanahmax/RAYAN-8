// Testbench for the RAYAN-8 Status Flag Register.
`timescale 1ns/1ps
module status_flags_tb;
    reg clk = 0;
    reg reset, en;
    reg z_in, c_in;
    wire z, c;

    integer errors = 0;
    integer checks = 0;

    status_flags dut (
        .clk(clk), .reset(reset), .en(en),
        .z_in(z_in), .c_in(c_in), .z(z), .c(c)
    );

    always #5 clk = ~clk;

    task step(input rst, input e, input zz, input cc);
        begin
            @(negedge clk);
            reset = rst; en = e; z_in = zz; c_in = cc;
            @(negedge clk);
        end
    endtask

    task checkzc(input gz, input gc, input ez, input ec, input [511:0] name);
        begin
            checks = checks + 1;
            if (gz !== ez || gc !== ec) begin
                errors = errors + 1;
                $display("FAIL %0s: got z=%0b c=%0b expected z=%0b c=%0b",
                         name, gz, gc, ez, ec);
            end else begin
                $display("PASS %0s: z=%0b c=%0b", name, gz, gc);
            end
        end
    endtask

    initial begin
        $dumpfile("build/status_flags.vcd");
        $dumpvars(0, status_flags_tb);

        reset = 1; en = 0; z_in = 0; c_in = 0;
        step(1, 0, 1'b0, 1'b0); checkzc(z, c, 1'b0, 1'b0, "reset clears flags");
        step(0, 1, 1'b1, 1'b0); checkzc(z, c, 1'b1, 1'b0, "capture Z=1");
        step(0, 0, 1'b0, 1'b1); checkzc(z, c, 1'b1, 1'b0, "en=0 holds");
        step(0, 1, 1'b0, 1'b1); checkzc(z, c, 1'b0, 1'b1, "capture C=1");
        step(1, 1, 1'b1, 1'b1); checkzc(z, c, 1'b0, 1'b0, "reset wins over en");

        if (errors == 0)
            $display("ALL %0d STATUS FLAG TESTS PASSED", checks);
        else
            $display("%0d of %0d STATUS FLAG TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
