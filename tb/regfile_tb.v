// Testbench for the RAYAN-8 Register File.
// Checks write, read-back on both ports, write-enable gating, and overwrite.
`timescale 1ns/1ps
module regfile_tb;
    reg        clk = 0;
    reg        wen;
    reg [1:0]  raddr_a, raddr_b, waddr;
    reg [7:0]  wdata;
    wire [7:0] rdata_a, rdata_b;

    integer errors = 0;
    integer checks = 0;

    regfile dut (
        .clk(clk), .wen(wen),
        .raddr_a(raddr_a), .raddr_b(raddr_b),
        .waddr(waddr), .wdata(wdata),
        .rdata_a(rdata_a), .rdata_b(rdata_b)
    );

    // Free-running clock, 10 ns period.
    always #5 clk = ~clk;

    task do_write(input [1:0] addr, input [7:0] data);
        begin
            @(negedge clk);
            waddr = addr; wdata = data; wen = 1;
            @(negedge clk);   // the posedge in between captured the write
            wen = 0;
        end
    endtask

    task check8(input [7:0] got, input [7:0] exp, input [255:0] name);
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
        $dumpfile("build/regfile.vcd");
        $dumpvars(0, regfile_tb);

        wen = 0; raddr_a = 0; raddr_b = 0; waddr = 0; wdata = 0;
        #12;

        // Write all four registers.
        do_write(2'd0, 8'd10);
        do_write(2'd1, 8'd20);
        do_write(2'd2, 8'd30);
        do_write(2'd3, 8'd40);

        // Read each back through port A.
        raddr_a = 2'd0; #1; check8(rdata_a, 8'd10, "read R0");
        raddr_a = 2'd1; #1; check8(rdata_a, 8'd20, "read R1");
        raddr_a = 2'd2; #1; check8(rdata_a, 8'd30, "read R2");
        raddr_a = 2'd3; #1; check8(rdata_a, 8'd40, "read R3");

        // Dual read: port A = R1, port B = R3 at the same time.
        raddr_a = 2'd1; raddr_b = 2'd3; #1;
        check8(rdata_a, 8'd20, "port A reads R1");
        check8(rdata_b, 8'd40, "port B reads R3");

        // Write-enable off must block the write. Try to put 99 into R0 with wen=0.
        @(negedge clk); waddr = 2'd0; wdata = 8'd99; wen = 1'b0;
        @(negedge clk);
        raddr_a = 2'd0; #1; check8(rdata_a, 8'd10, "wen=0 blocks write, R0 stays 10");

        // Overwrite R1.
        do_write(2'd1, 8'd200);
        raddr_a = 2'd1; #1; check8(rdata_a, 8'd200, "overwrite R1 = 200");

        if (errors == 0)
            $display("ALL %0d REGFILE TESTS PASSED", checks);
        else
            $display("%0d of %0d REGFILE TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
