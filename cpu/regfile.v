// Register File: 32 x 32-bit registers, 2 read ports, 1 write port
// x0 hardwired to zero, read-during-write forwarding
module regfile (
    input  wire        clk,
    input  wire        reg_write,    // write enable
    input  wire [4:0]  rs1,          // read address 1
    input  wire [4:0]  rs2,          // read address 2
    input  wire [4:0]  rd,           // write address
    input  wire [31:0] rd_data,      // write data
    output wire [31:0] rs1_data,     // read data 1
    output wire [31:0] rs2_data      // read data 2
);

    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0000_0000;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (reg_write && rd != 5'b0)
            regs[rd] <= rd_data;
    end

    // Asynchronous read with RDW forwarding
    assign rs1_data = (rs1 == 5'b0) ? 32'h0000_0000 :
                      (reg_write && rs1 == rd) ? rd_data :
                      regs[rs1];

    assign rs2_data = (rs2 == 5'b0) ? 32'h0000_0000 :
                      (reg_write && rs2 == rd) ? rd_data :
                      regs[rs2];

endmodule
