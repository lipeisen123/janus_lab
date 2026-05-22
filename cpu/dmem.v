// Data Memory: 4KB byte-addressable RAM, supports LB/LH/LW/LBU/LHU/SB/SH/SW
// Combinational read, synchronous write
module dmem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,         // byte address
    input  wire [2:0]  funct3,       // sub-word access type
    input  wire [31:0] wd_data,      // write data (from rs2)
    output reg  [31:0] rd_data       // read data
);

    // 4096 x 8-bit = 4KB byte-addressable RAM
    reg [7:0] mem [0:4095];
    integer i;

    initial begin
        for (i = 0; i < 4096; i = i + 1)
            mem[i] = 8'h00;
    end

    wire [31:0] word_addr;
    assign word_addr = {addr[31:2], 2'b00};  // word-align the address

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[word_addr]       <= wd_data[7:0];            // SB
                3'b001: begin                                            // SH
                    mem[word_addr]     <= wd_data[7:0];
                    mem[word_addr + 1] <= wd_data[15:8];
                end
                3'b010: begin                                            // SW
                    mem[word_addr]     <= wd_data[7:0];
                    mem[word_addr + 1] <= wd_data[15:8];
                    mem[word_addr + 2] <= wd_data[23:16];
                    mem[word_addr + 3] <= wd_data[31:24];
                end
                default: begin
                    mem[word_addr]     <= wd_data[7:0];
                    mem[word_addr + 1] <= wd_data[15:8];
                    mem[word_addr + 2] <= wd_data[23:16];
                    mem[word_addr + 3] <= wd_data[31:24];
                end
            endcase
        end
    end

    // Combinational read
    always @(*) begin
        rd_data = 32'h0000_0000;
        if (mem_read) begin
            case (funct3)
                3'b000: // LB (signed byte)
                    rd_data = {{24{mem[word_addr][7]}}, mem[word_addr]};

                3'b001: // LH (signed halfword)
                    rd_data = {{16{mem[word_addr + 1][7]}}, mem[word_addr + 1], mem[word_addr]};

                3'b010: // LW (word)
                    rd_data = {mem[word_addr + 3], mem[word_addr + 2],
                               mem[word_addr + 1], mem[word_addr]};

                3'b100: // LBU (unsigned byte)
                    rd_data = {24'h000000, mem[word_addr]};

                3'b101: // LHU (unsigned halfword)
                    rd_data = {16'h0000, mem[word_addr + 1], mem[word_addr]};

                default: rd_data = {mem[word_addr + 3], mem[word_addr + 2],
                                    mem[word_addr + 1], mem[word_addr]};
            endcase
        end
    end

endmodule
