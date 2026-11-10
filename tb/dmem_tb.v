// Testbench for the RAYAN-8 Data Memory.
// Checks clocked write, combinational read-back, write-enable gating, overwrite.
`timescale 1ns/1ps
module dmem_tb;
    reg        clk = 0;
    reg        memwrite;
    reg  [7:0] addr, wdata;
    wire [7:0] rdata;

    integer errors = 0;
    integer checks = 0;

    dmem dut (
        .clk(clk), .memwrite(memwrite),
        .addr(addr), .wdata(wdata), .rdata(rdata)
    );

    always #5 clk = ~clk;

    task do_write(input [7:0] a, input [7:0] d);
        begin
            @(negedge clk);
            addr = a; wdata = d; memwrite = 1;
            @(negedge clk);   // posedge in between captured the write
            memwrite = 0;
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
        $dumpfile("build/dmem.vcd");
        $dumpvars(0, dmem_tb);

        memwrite = 0; addr = 0; wdata = 0;
        #12;

        do_write(8'd20, 8'd100);
        do_write(8'd21, 8'd200);
        do_write(8'd255, 8'd7);

        addr = 8'd20;  #1; check8(rdata, 8'd100, "read RAM[20]");
        addr = 8'd21;  #1; check8(rdata, 8'd200, "read RAM[21]");
        addr = 8'd255; #1; check8(rdata, 8'd7,   "read RAM[255]");

        // memwrite low must block the write.
        @(negedge clk); addr = 8'd20; wdata = 8'd99; memwrite = 1'b0;
        @(negedge clk);
        addr = 8'd20; #1; check8(rdata, 8'd100, "memwrite=0 blocks, RAM[20] stays 100");

        // Overwrite.
        do_write(8'd20, 8'd7);
        addr = 8'd20; #1; check8(rdata, 8'd7, "overwrite RAM[20]=7");

        if (errors == 0)
            $display("ALL %0d DMEM TESTS PASSED", checks);
        else
            $display("%0d of %0d DMEM TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
