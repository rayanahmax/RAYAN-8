// Testbench for the RAYAN-8 Control Unit.
// Drives opcodes through the FSM and checks state transitions and control signals.
`timescale 1ns/1ps
module control_unit_tb;
    reg        clk = 0;
    reg        reset;
    reg  [3:0] opcode;
    reg        z, c;

    wire       ir_en, pc_en, nextpc_sel, rf_wen, bsel, wb_sel, memwrite, flag_en, halt;
    wire [2:0] alu_op;

    integer errors = 0;
    integer checks = 0;
    integer cycles;

    control_unit dut (
        .clk(clk), .reset(reset), .opcode(opcode), .z(z), .c(c),
        .ir_en(ir_en), .pc_en(pc_en), .nextpc_sel(nextpc_sel), .rf_wen(rf_wen),
        .alu_op(alu_op), .bsel(bsel), .wb_sel(wb_sel), .memwrite(memwrite),
        .flag_en(flag_en), .halt(halt)
    );

    always #5 clk = ~clk;

    localparam OP_LDI=4'h0, OP_ADD=4'h1, OP_SUB=4'h2, OP_AND=4'h3, OP_OR=4'h4,
               OP_XOR=4'h5, OP_NOT=4'h6, OP_MOV=4'h7, OP_LOAD=4'h8, OP_STORE=4'h9,
               OP_JMP=4'hA, OP_JZ=4'hB, OP_JC=4'hC, OP_HALT=4'hD;
    localparam S_FETCH=3'd0, S_DECODE=3'd1, S_EXEC=3'd2, S_MEM=3'd3, S_WB=3'd4, S_HALT=3'd5;

    task expect(input cond, input [511:0] msg);
        begin
            checks = checks + 1;
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL: %0s", msg);
            end
        end
    endtask

    // Run one instruction starting from FETCH.
    task run_one(input [3:0] opc, input zz, input cc, output integer cyc);
        reg [2:0] st;
        begin
            opcode = opc; z = zz; c = cc;
            #1; cyc = 0; st = dut.state;

            expect(st == S_FETCH, "starts in FETCH");
            expect(ir_en && pc_en && !nextpc_sel, "FETCH: ir_en=1 pc_en=1 sel=0");
            @(posedge clk); #1; cyc = cyc + 1;

            st = dut.state;
            expect(st == S_DECODE, "FETCH->DECODE");
            expect(!ir_en && !rf_wen && !memwrite && !flag_en, "DECODE idle");
            @(posedge clk); #1; cyc = cyc + 1;

            st = dut.state;
            expect(st == S_EXEC, "DECODE->EXEC");
            if (opc == OP_ADD)
                expect(flag_en && alu_op == 3'd0 && !bsel, "EXEC ADD: flag, op=ADD, bsel=0");
            else if (opc == OP_LDI)
                expect(flag_en && alu_op == 3'd6 && bsel, "EXEC LDI: flag, op=PASS, bsel=1");
            else if (opc == OP_STORE)
                expect(!flag_en, "EXEC STORE: no flag capture");
            else if (opc == OP_JZ)
                expect(!flag_en, "EXEC JZ: no flag capture");
            @(posedge clk); #1; cyc = cyc + 1;

            st = dut.state;
            if (opc == OP_LOAD || opc == OP_STORE) begin
                expect(st == S_MEM, "EXEC->MEM (load/store)");
                expect(memwrite == (opc == OP_STORE), "MEM: memwrite only for STORE");
                @(posedge clk); #1; cyc = cyc + 1;
                st = dut.state;
                if (opc == OP_LOAD) begin
                    expect(st == S_WB, "MEM->WB (load)");
                    expect(rf_wen && wb_sel, "WB LOAD: write reg from DMEM");
                    @(posedge clk); #1; cyc = cyc + 1;
                    expect(dut.state == S_FETCH, "LOAD done -> FETCH");
                end else begin
                    expect(st == S_FETCH, "STORE done -> FETCH (no WB)");
                end
            end else if (opc == OP_HALT) begin
                expect(st == S_HALT, "EXEC->HALT");
                expect(halt, "HALT asserted");
            end else begin
                expect(st == S_WB, "EXEC->WB");
                if (opc == OP_ADD || opc == OP_LDI)
                    expect(rf_wen && !wb_sel, "WB reg: write from ALU");
                else if (opc == OP_JZ) begin
                    if (zz) expect(pc_en && nextpc_sel, "WB JZ taken: pc<=target");
                    else    expect(!pc_en, "WB JZ not taken: pc held");
                end
                @(posedge clk); #1; cyc = cyc + 1;
                expect(dut.state == S_FETCH, "done -> FETCH");
            end
        end
    endtask

    initial begin
        $dumpfile("build/control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        reset = 1; opcode = OP_ADD; z = 0; c = 0;
        @(negedge clk); #1;
        expect(dut.state == S_FETCH && !halt, "reset -> FETCH, not halted");
        @(negedge clk); reset = 0;

        run_one(OP_ADD,   0, 0, cycles); $display("ADD cycles = %0d", cycles);
        run_one(OP_LDI,   0, 0, cycles); $display("LDI cycles = %0d", cycles);
        run_one(OP_LOAD,  0, 0, cycles); $display("LOAD cycles = %0d", cycles);
        run_one(OP_STORE, 0, 0, cycles); $display("STORE cycles = %0d", cycles);
        run_one(OP_JZ,    1, 0, cycles); $display("JZ taken cycles = %0d", cycles);
        run_one(OP_JZ,    0, 0, cycles); $display("JZ not taken cycles = %0d", cycles);
        run_one(OP_HALT,  0, 0, cycles); $display("HALT cycles = %0d", cycles);

        if (errors == 0)
            $display("ALL %0d CONTROL UNIT CHECKS PASSED", checks);
        else
            $display("%0d of %0d CONTROL UNIT CHECKS FAILED", errors, checks);
        $finish;
    end
endmodule
