// RAYAN-8 CPU datapath (Phase 4 integration)
// Wires PC, instruction memory, IR, control unit, register file, ALU,
// operand-B mux, write-back mux, data memory, status flags, and PC incrementer.
`default_nettype none
module cpu #(
    parameter INIT_FILE = ""
)(
    input  wire clk,
    input  wire reset
);
    // Program counter
    wire       pc_en, nextpc_sel;
    wire [7:0] pc, pc_plus1, jump_target, next_pc;
    pc_inc u_pcinc (.pc(pc), .pc_next(pc_plus1));
    assign next_pc = nextpc_sel ? jump_target : pc_plus1;
    pc u_pc (.clk(clk), .reset(reset), .en(pc_en), .d(next_pc), .q(pc));

    // Instruction fetch
    wire [15:0] instr;
    imem #(.INIT_FILE(INIT_FILE)) u_imem (.addr(pc), .dout(instr));

    // Instruction register
    wire       ir_en;
    wire [15:0] ir_q;
    ir u_ir (.clk(clk), .reset(reset), .en(ir_en), .d(instr), .q(ir_q));

    // Instruction fields
    wire [3:0] opcode = ir_q[15:12];
    wire [1:0] rd_f   = ir_q[11:10];
    wire [1:0] rs_f   = ir_q[9:8];
    wire [7:0] imm    = ir_q[7:0];
    assign jump_target = imm;

    // Status flags
    wire flag_en, z, c, z_in, c_in;
    status_flags u_flags (
        .clk(clk), .reset(reset), .en(flag_en),
        .z_in(z_in), .c_in(c_in), .z(z), .c(c)
    );

    // Control unit
    wire rf_wen, bsel, wb_sel, memwrite, halt;
    wire [2:0] alu_op;
    control_unit u_cu (
        .clk(clk), .reset(reset), .opcode(opcode), .z(z), .c(c),
        .ir_en(ir_en), .pc_en(pc_en), .nextpc_sel(nextpc_sel), .rf_wen(rf_wen),
        .alu_op(alu_op), .bsel(bsel), .wb_sel(wb_sel), .memwrite(memwrite),
        .flag_en(flag_en), .halt(halt)
    );

    // Register file: port A reads RD, port B reads RS
    wire [7:0] rdata_a, rdata_b, wb_data;
    regfile u_rf (
        .clk(clk), .reset(reset), .wen(rf_wen),
        .raddr_a(rd_f), .raddr_b(rs_f),
        .waddr(rd_f), .wdata(wb_data),
        .rdata_a(rdata_a), .rdata_b(rdata_b)
    );

    // ALU operand B mux: 0 = RS, 1 = immediate
    wire [7:0] alu_b;
    assign alu_b = bsel ? imm : rdata_b;

    // ALU
    wire [7:0] alu_result;
    alu u_alu (
        .a(rdata_a), .b(alu_b), .op(alu_op),
        .result(alu_result), .zero(z_in), .carry(c_in)
    );

    // Data memory: address and store data from instruction/RD, read feeds WB mux
    wire [7:0] dmem_rdata;
    dmem u_dmem (
        .clk(clk), .memwrite(memwrite), .addr(imm), .wdata(rdata_a), .rdata(dmem_rdata)
    );

    // Write-back mux: 0 = ALU result, 1 = data memory
    assign wb_data = wb_sel ? dmem_rdata : alu_result;
endmodule
