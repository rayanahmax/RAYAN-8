// RAYAN-8 Status Flag Register
// Holds the Zero and Carry flags. Reset clears both. With en high,
// captures the incoming flag values. With en low, holds.
`default_nettype none
module status_flags (
    input  wire clk,
    input  wire reset,
    input  wire en,
    input  wire z_in,
    input  wire c_in,
    output reg  z,
    output reg  c
);
    always @(posedge clk) begin
        if (reset) begin
            z <= 1'b0;
            c <= 1'b0;
        end else if (en) begin
            z <= z_in;
            c <= c_in;
        end
    end
endmodule
