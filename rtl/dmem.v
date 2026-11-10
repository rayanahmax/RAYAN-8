// RAYAN-8 Data Memory (RAM)
// 256 locations x 8 bits. Combinational read, clocked write on MemWrite.
`default_nettype none
module dmem (
    input  wire       clk,
    input  wire       memwrite,
    input  wire [7:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);
    reg [7:0] mem [0:255];

    assign rdata = mem[addr];

    always @(posedge clk) begin
        if (memwrite) begin
            mem[addr] <= wdata;
        end
    end
endmodule
