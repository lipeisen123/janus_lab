module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] wdata3,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] regs [0:31];

    // 同步写，x0 硬编码为 0，写入 x0 静默丢弃
    always_ff @(posedge clk) begin
        if (we3 && (rd != 5'b0)) regs[rd] <= wdata3;
    end

    // 异步读：ID 阶段立即输出，不等待时钟边沿
    always_comb begin
        rdata1 = (rs1 == 5'b0) ? 32'h0 : regs[rs1];
        rdata2 = (rs2 == 5'b0) ? 32'h0 : regs[rs2];
    end
endmodule
