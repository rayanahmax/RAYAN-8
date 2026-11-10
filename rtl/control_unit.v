// RAYAN-8 Control Unit
// Multi-cycle FSM plus opcode decoder. Produces all datapath control signals.
// States: FETCH, DECODE, EXEC, MEM, WB, HALT.
`default_nettype none
module control_unit (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode,   // IR[15:12]
    input  wire       z,        // Zero flag
    input  wire       c,        // Carry flag

    output reg        ir_en,      // load IR
    output reg        pc_en,      // load PC
    output reg        nextpc_sel, // 0 = PC+1, 1 = jump target
    output reg        rf_wen,     // register file write enable
    output reg  [2:0] alu_op,     // ALU operation select
    output reg        bsel,       // ALU operand B: 0 = RS, 1 = immediate
    output reg        wb_sel,     // write-back source: 0 = ALU, 1 = DMEM
    output reg        memwrite,   // data memory write enable
    output reg        flag_en,    // capture Z/C into status register
    output reg        halt        // processor stopped
);
    // Instruction opcodes (matches ISA v1.0)
    localparam OP_LDI  = 4'h0, OP_ADD = 4'h1, OP_SUB = 4'h2, OP_AND = 4'h3,
               OP_OR   = 4'h4, OP_XOR = 4'h5, OP_NOT = 4'h6, OP_MOV = 4'h7,
               OP_LOAD = 4'h8, OP_STORE = 4'h9, OP_JMP = 4'hA, OP_JZ = 4'hB,
               OP_JC   = 4'hC, OP_HALT = 4'hD;

    // ALU operation encoding (matches rtl/alu.v)
    localparam A_ADD = 3'd0, A_SUB = 3'd1, A_AND = 3'd2, A_OR = 3'd3,
               A_XOR = 3'd4, A_NOT = 3'd5, A_PASS = 3'd6;

    // FSM states
    localparam S_FETCH = 3'd0, S_DECODE = 3'd1, S_EXEC = 3'd2,
               S_MEM   = 3'd3, S_WB     = 3'd4, S_HALT = 3'd5;

    reg [2:0] state;

    // Opcode classification
    wire is_alu    = (opcode == OP_ADD) || (opcode == OP_SUB) || (opcode == OP_AND) ||
                     (opcode == OP_OR)  || (opcode == OP_XOR) || (opcode == OP_NOT);
    wire is_pass   = (opcode == OP_LDI) || (opcode == OP_MOV);
    wire is_load   = (opcode == OP_LOAD);
    wire is_store  = (opcode == OP_STORE);
    wire is_branch = (opcode == OP_JMP) || (opcode == OP_JZ) || (opcode == OP_JC);
    wire writes_reg = is_alu || is_pass || is_load;
    wire taken     = (opcode == OP_JMP) || (opcode == OP_JZ && z) || (opcode == OP_JC && c);

    function [2:0] alu_decode;
        input [3:0] op;
        begin
            case (op)
                OP_ADD:  alu_decode = A_ADD;
                OP_SUB:  alu_decode = A_SUB;
                OP_AND:  alu_decode = A_AND;
                OP_OR:   alu_decode = A_OR;
                OP_XOR:  alu_decode = A_XOR;
                OP_NOT:  alu_decode = A_NOT;
                OP_LDI:  alu_decode = A_PASS;
                OP_MOV:  alu_decode = A_PASS;
                default: alu_decode = A_ADD;
            endcase
        end
    endfunction

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= S_FETCH;
        else begin
            case (state)
                S_FETCH:  state <= S_DECODE;
                S_DECODE: state <= S_EXEC;
                S_EXEC: begin
                    if (opcode == OP_HALT)     state <= S_HALT;
                    else if (is_load || is_store) state <= S_MEM;
                    else                          state <= S_WB;
                end
                S_MEM:    state <= is_load ? S_WB : S_FETCH;  // STORE ends, LOAD writes back
                S_WB:     state <= S_FETCH;
                S_HALT:   state <= S_HALT;
                default:  state <= S_FETCH;
            endcase
        end
    end

    // Combinational control outputs (Moore: function of state and opcode)
    always @(*) begin
        ir_en      = 1'b0;
        pc_en      = 1'b0;
        nextpc_sel = 1'b0;
        rf_wen     = 1'b0;
        alu_op     = A_ADD;
        bsel       = 1'b0;
        wb_sel     = 1'b0;
        memwrite   = 1'b0;
        flag_en    = 1'b0;
        halt       = 1'b0;

        case (state)
            S_FETCH: begin
                ir_en = 1'b1;
                pc_en = 1'b1;      // nextpc_sel = 0, so PC <= PC+1
            end
            S_DECODE: begin
                // register reads are combinational; nothing to assert
            end
            S_EXEC: begin
                alu_op  = alu_decode(opcode);
                bsel    = (opcode == OP_LDI);
                flag_en = is_alu || is_pass;
            end
            S_MEM: begin
                memwrite = is_store;
            end
            S_WB: begin
                rf_wen = writes_reg;
                wb_sel = is_load;
                if (is_branch && taken) begin
                    pc_en      = 1'b1;
                    nextpc_sel = 1'b1;   // PC <= jump target
                end
            end
            S_HALT: begin
                halt = 1'b1;
            end
            default: ;
        endcase
    end
endmodule
