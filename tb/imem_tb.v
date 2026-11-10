// Testbench for the RAYAN-8 Instruction Memory.
// Loads a small hex image and checks combinational reads at several addresses.
`timescale 1ns/1ps
module imem_tb;
    reg  [7:0]  addr;
    wire [15:0] dout;

    integer errors = 0;
    integer checks = 0;

    imem #(.INIT_FILE("tests/programs/imem_init.hex")) dut (
        .addr(addr), .dout(dout)
    );

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
        $dumpfile("build/imem.vcd");
        $dumpvars(0, imem_tb);

        addr = 8'd0; #1; check16(dout, 16'h000F, "imem[0]");
        addr = 8'd1; #1; check16(dout, 16'h001E, "imem[1]");
        addr = 8'd2; #1; check16(dout, 16'h0102, "imem[2]");
        addr = 8'd3; #1; check16(dout, 16'h1600, "imem[3]");
        addr = 8'd4; #1; check16(dout, 16'h9814, "imem[4]");

        // Re-read address 0 to confirm combinational output follows the address.
        addr = 8'd0; #1; check16(dout, 16'h000F, "back to imem[0]");

        if (errors == 0)
            $display("ALL %0d IMEM TESTS PASSED", checks);
        else
            $display("%0d of %0d IMEM TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
