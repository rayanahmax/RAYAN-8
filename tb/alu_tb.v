// Testbench for the RAYAN-8 ALU.
// Exercises ADD, SUB, AND, OR, XOR, NOT and the Z / C flags.
`timescale 1ns/1ps
module alu_tb;
    reg  [7:0] a, b;
    reg  [2:0] op;
    wire [7:0] result;
    wire       zero, carry;

    integer errors = 0;
    integer checks = 0;

    alu dut (
        .a(a), .b(b), .op(op),
        .result(result), .zero(zero), .carry(carry)
    );

    task check(input [7:0] exp_r, input exp_z, input exp_c, input [255:0] name);
        begin
            checks = checks + 1;
            if (result !== exp_r || zero !== exp_z || carry !== exp_c) begin
                errors = errors + 1;
                $display("FAIL %0s: got r=%0d z=%0b c=%0b, expected r=%0d z=%0b c=%0b",
                         name, result, zero, carry, exp_r, exp_z, exp_c);
            end else begin
                $display("PASS %0s: r=%0d z=%0b c=%0b", name, result, zero, carry);
            end
        end
    endtask

    initial begin
        // ADD  (op = 0)
        op = 3'd0;
        a = 8'd20;  b = 8'd22;  #1; check(8'd44 - 2, 1'b0, 1'b0, "ADD 20+22=42");
        a = 8'd200; b = 8'd100; #1; check(8'd44,     1'b0, 1'b1, "ADD 200+100 carry");
        a = 8'd0;   b = 8'd0;   #1; check(8'd0,      1'b1, 1'b0, "ADD 0+0 zero");

        // SUB  (op = 1)
        op = 3'd1;
        a = 8'd50; b = 8'd20; #1; check(8'd30,  1'b0, 1'b0, "SUB 50-20");
        a = 8'd20; b = 8'd50; #1; check(8'd226, 1'b0, 1'b1, "SUB 20-50 borrow");
        a = 8'd7;  b = 8'd7;  #1; check(8'd0,   1'b1, 1'b0, "SUB 7-7 zero");

        // AND  (op = 2)
        op = 3'd2; a = 8'hF0; b = 8'h3C; #1; check(8'h30, 1'b0, 1'b0, "AND F0&3C");

        // OR   (op = 3)
        op = 3'd3; a = 8'h0F; b = 8'hF0; #1; check(8'hFF, 1'b0, 1'b0, "OR 0F|F0");

        // XOR  (op = 4)
        op = 3'd4; a = 8'hAA; b = 8'hFF; #1; check(8'h55, 1'b0, 1'b0, "XOR AA^FF");

        // NOT  (op = 5)
        op = 3'd5; b = 8'h0F; #1; check(8'hF0, 1'b0, 1'b0, "NOT 0F");
        b = 8'hFF; #1; check(8'h00, 1'b1, 1'b0, "NOT FF zero");

        if (errors == 0)
            $display("ALL %0d ALU TESTS PASSED", checks);
        else
            $display("%0d of %0d ALU TESTS FAILED", errors, checks);
        $finish;
    end
endmodule
