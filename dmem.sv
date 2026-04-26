module dmem (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    // 4KB RAM，字节寻址
    logic [7:0] ram [0:4095];
    logic [31:0] aligned_wdata;

    // 写对齐：单周期内写入 32-bit word
    always_ff @(posedge clk) begin
        if (mem_write) begin
            aligned_wdata <= wdata;
            ram[addr]     <= wdata[7:0];
            ram[addr+1]   <= wdata[15:8];
            ram[addr+2]   <= wdata[23:16];
            ram[addr+3]   <= wdata[31:24];
        end
    end

    // 组合读：同一周期内输出有效数据
    always_comb begin
        if (mem_read) begin
            rdata = {ram[addr+3], ram[addr+2], ram[addr+1], ram[addr]};
        end else begin
            rdata = 32'h0;
        end
    end
endmodule
