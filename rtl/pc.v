// RAYAN-8 Program Counter
// 8-bit. Reset clears to 0. With en high, loads the next value from the
// Next-PC Selection mux. With en low, holds. Reset has priority over en.
`default_nettype none
module pc (
    input  wire       clk,
    input  wire       reset,
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk) begin
        if (reset)      q <= 8'd0;
        else if (en)    q <= d;
    end
endmodule
