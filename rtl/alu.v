// RAYAN-8 ALU
// 8-bit arithmetic/logic unit with Zero and Carry flags.
// op encoding is internal; the control unit maps instruction opcode to it.
`default_nettype none
module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] op,
    output wire [7:0] result,
    output wire       zero,
    output wire       carry
);
    localparam OP_ADD = 3'd0,
               OP_SUB = 3'd1,
               OP_AND = 3'd2,
               OP_OR  = 3'd3,
               OP_XOR = 3'd4,
               OP_NOT = 3'd5;

    wire [8:0] sum  = {1'b0, a} + {1'b0, b};
    wire [8:0] diff = {1'b0, a} - {1'b0, b};

    reg [7:0] r;
    reg       c;

    always @(*) begin
        r = 8'd0;
        c = 1'b0;
        case (op)
            OP_ADD: begin r = sum[7:0];  c = sum[8];  end
            OP_SUB: begin r = diff[7:0]; c = diff[8]; end
            OP_AND: r = a & b;
            OP_OR:  r = a | b;
            OP_XOR: r = a ^ b;
            OP_NOT: r = ~b;
            default: begin r = 8'd0; c = 1'b0; end
        endcase
    end

    assign result = r;
    assign carry  = c;
    assign zero   = (r == 8'd0);
endmodule
