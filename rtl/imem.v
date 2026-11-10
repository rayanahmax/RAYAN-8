// RAYAN-8 Instruction Memory (ROM)
// 256 locations x 16 bits. Combinational read, addressed by the PC.
// Read-only during execution. Optionally loads a program image via INIT_FILE.
`default_nettype none
module imem #(
    parameter INIT_FILE = ""
)(
    input  wire [7:0]  addr,
    output wire [15:0] dout
);
    reg [15:0] mem [0:255];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    assign dout = mem[addr];
endmodule
