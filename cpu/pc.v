// Program Counter: 32-bit register with reset, enable, and stall
module pc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pc_stall,   // stall PC (for load-use hazard)
    input  wire [31:0] pc_next,    // next PC value
    output wire [31:0] pc_current  // current PC output
);

    reg [31:0] pc_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_reg <= 32'h0000_0000;
        else if (!pc_stall)
            pc_reg <= pc_next;
    end

    assign pc_current = pc_reg;

endmodule
