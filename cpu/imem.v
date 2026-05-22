// Instruction Memory: 1KB ROM (256 x 32-bit words), combinational read
module imem (
    input  wire [31:0] addr,       // byte address (lower 2 bits ignored for word-aligned)
    output wire [31:0] instr       // 32-bit instruction
);

    // 256 words x 32 bits = 1KB
    reg [31:0] rom [0:255];

    // ROM is loaded from prog.hex during simulation (via $readmemh)
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 32'h0000_0013;  // NOP: ADDI x0, x0, 0
        // $readmemh("prog.hex", rom);  // uncomment for hex loading
    end

    // Combinational read: word-aligned, little-endian
    assign instr = rom[addr[31:2]];

endmodule
