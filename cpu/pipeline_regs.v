// Pipeline Registers: IF/ID, ID/EX, EX/MEM, MEM/WB
// Supports stall (hold) and flush (insert NOP)
module if_id_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,          // hold current values
    input  wire        flush,          // insert NOP (all zeros)
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 32'h0000_0000;
            instr_out <= 32'h0000_0013;  // NOP
        end else if (flush) begin
            pc_out    <= 32'h0000_0000;
            instr_out <= 32'h0000_0013;  // all-zero control = NOP
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
        // else: hold (stall asserted)
    end

endmodule


module id_ex_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,          // insert NOP bubble

    // Control signals (from ID)
    input  wire        reg_write_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_op_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        jump_in,

    // Data (from ID)
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [2:0]  funct3_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [6:0]  funct7_in,
    input  wire [6:0]  opcode_in,
    input  wire [31:0] instr_in,

    // Outputs to EX stage
    output reg         reg_write_out,
    output reg         alu_src_out,
    output reg  [1:0]  alu_op_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,
    output reg  [2:0]  funct3_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [6:0]  funct7_out,
    output reg  [6:0]  opcode_out,
    output reg  [31:0] instr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_op_out     <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            pc_out         <= 32'h0000_0000;
            rs1_data_out   <= 32'h0000_0000;
            rs2_data_out   <= 32'h0000_0000;
            imm_out        <= 32'h0000_0000;
            funct3_out     <= 3'b000;
            rs1_out        <= 5'b0;
            rs2_out        <= 5'b0;
            rd_out         <= 5'b0;
            funct7_out     <= 7'b0;
            opcode_out     <= 7'b0;
            instr_out      <= 32'h0000_0013;
        end else if (flush) begin
            // Insert NOP bubble (all control signals = 0)
            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_op_out     <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            rd_out         <= 5'b0;
            // Other data fields: don't care when control is NOP
        end else begin
            reg_write_out  <= reg_write_in;
            alu_src_out    <= alu_src_in;
            alu_op_out     <= alu_op_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_out        <= imm_in;
            funct3_out     <= funct3_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct7_out     <= funct7_in;
            opcode_out     <= opcode_in;
            instr_out      <= instr_in;
        end
    end

endmodule


module ex_mem_reg (
    input  wire        clk,
    input  wire        rst_n,

    // Control signals
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,

    // Data
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire        branch_taken_in,
    input  wire        jump_in,
    input  wire [31:0] pc_target_in,

    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_data_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg         branch_taken_out,
    output reg         jump_out,
    output reg  [31:0] pc_target_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            alu_result_out    <= 32'h0000_0000;
            rs2_data_out      <= 32'h0000_0000;
            rd_out            <= 5'b0;
            funct3_out        <= 3'b000;
            branch_taken_out  <= 1'b0;
            jump_out          <= 1'b0;
            pc_target_out     <= 32'h0000_0000;
        end else begin
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
            alu_result_out    <= alu_result_in;
            rs2_data_out      <= rs2_data_in;
            rd_out            <= rd_in;
            funct3_out        <= funct3_in;
            branch_taken_out  <= branch_taken_in;
            jump_out          <= jump_in;
            pc_target_out     <= pc_target_in;
        end
    end

endmodule


module mem_wb_reg (
    input  wire        clk,
    input  wire        rst_n,

    // Control signals
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,

    // Data
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_rd_data_in,
    input  wire [4:0]  rd_in,

    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_rd_data_out,
    output reg  [4:0]  rd_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out   <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            alu_result_out  <= 32'h0000_0000;
            mem_rd_data_out <= 32'h0000_0000;
            rd_out          <= 5'b0;
        end else begin
            reg_write_out   <= reg_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            alu_result_out  <= alu_result_in;
            mem_rd_data_out <= mem_rd_data_in;
            rd_out          <= rd_in;
        end
    end

endmodule
