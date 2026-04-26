module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  ctrl,
    output logic [31:0] res,
    output logic        zero
);
    always_comb begin
        res = 32'h0;
        unique case (ctrl)
            4'b0000: res = a + b;          // ADD
            4'b0001: res = a - b;          // SUB
            4'b0010: res = a << b[4:0];    // SLL
            4'b0011: res = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0; // SLT
            4'b0100: res = (a < b) ? 32'h1 : 32'h0; // SLTU
            4'b0101: res = a ^ b;          // XOR
            4'b0110: res = a >> b[4:0];    // SRL
            4'b0111: res = $signed(a) >>> b[4:0]; // SRA
            4'b1000: res = a | b;          // OR
            4'b1001: res = a & b;          // AND
            default: res = 32'h0;
        endcase
    end
    assign zero = (res == 32'h0);
endmodule
