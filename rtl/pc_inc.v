// RAYAN-8 PC Incrementer
// Combinational +1 on the program counter.
`default_nettype none
module pc_inc (
    input  wire [7:0] pc,
    output wire [7:0] pc_next
);
    assign pc_next = pc + 8'd1;
endmodule
