// RAYAN-8 Register File
// Four 8-bit general-purpose registers, R0 to R3.
// Two combinational read ports (A and B) and one clocked write port.
`default_nettype none
module regfile (
    input  wire       clk,
    input  wire       reset,      // clear all registers to 0
    input  wire       wen,        // write enable
    input  wire [1:0] raddr_a,    // read port A address
    input  wire [1:0] raddr_b,    // read port B address
    input  wire [1:0] waddr,      // write address (RD)
    input  wire [7:0] wdata,      // write data
    output wire [7:0] rdata_a,    // Operand A
    output wire [7:0] rdata_b     // Operand B
);
    reg [7:0] regs [0:3];

    // Reads are combinational: the value appears as soon as the address is set.
    assign rdata_a = regs[raddr_a];
    assign rdata_b = regs[raddr_b];

    // Writes are synchronous. Reset clears all registers and has priority.
    always @(posedge clk) begin
        if (reset) begin
            regs[0] <= 8'd0;
            regs[1] <= 8'd0;
            regs[2] <= 8'd0;
            regs[3] <= 8'd0;
        end else if (wen) begin
            regs[waddr] <= wdata;
        end
    end
endmodule
