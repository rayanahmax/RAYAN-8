// RAYAN-8 Instruction Register
// 16-bit. Reset clears to 0. With en high, captures the fetched instruction.
`default_nettype none
module ir (
    input  wire        clk,
    input  wire        reset,
    input  wire        en,
    input  wire [15:0] d,
    output reg  [15:0] q
);
    always @(posedge clk) begin
        if (reset)   q <= 16'd0;
        else if (en) q <= d;
    end
endmodule
