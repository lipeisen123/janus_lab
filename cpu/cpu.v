// Single-Cycle RISC-V CPU (Phase 1)
// Harvard architecture, one instruction per clock cycle
// Five stages: IF ID EX MEM WB — all combinational, no pipeline registers
module cpu (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] pc_current,
    output wire [31:0] instr,
    output wire [31:0] alu_result,
    output wire [31:0] dmem_rd_data,
    output wire        reg_write_out,
    output wire        mem_write_out
);

    // =========================================================================
    // IF Stage — Fetch
    // =========================================================================
    wire [31:0] pc_next, pc_plus4;
    wire [31:0] imem_instr;

    assign pc_plus4 = pc_current + 32'd4;

    pc u_pc (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_stall   (1'b0),        // no stalling in single-cycle
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    imem u_imem (
        .addr (pc_current),
        .instr(imem_instr)
    );

    assign instr = imem_instr;

    // =========================================================================
    // ID Stage — Decode
    // =========================================================================
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] imm;
    wire        reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump;
    wire [1:0]  alu_op;

    regfile u_regfile (
        .clk       (clk),
        .reg_write (reg_write),
        .rs1       (imem_instr[19:15]),
        .rs2       (imem_instr[24:20]),
        .rd        (imem_instr[11:7]),
        .rd_data   (dmem_rd_data),    // WB data
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    immgen u_immgen (
        .opcode (imem_instr[6:0]),
        .instr  (imem_instr),
        .imm    (imm)
    );

    ctrl u_ctrl (
        .opcode     (imem_instr[6:0]),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .alu_op     (alu_op),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump)
    );

    // =========================================================================
    // EX Stage — Execute
    // =========================================================================
    wire [31:0] alu_a, alu_b;
    wire [3:0]  alu_ctrl;
    wire        zero;
    wire        branch_taken;

    assign alu_a = rs1_data;
    assign alu_b = alu_src ? imm : rs2_data;

    aluctrl u_aluctrl (
        .alu_op   (alu_op),
        .funct3   (imem_instr[14:12]),
        .funct7_5 (imem_instr[30]),
        .alu_ctrl (alu_ctrl)
    );

    alu u_alu (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero)
    );

    branch_unit u_branch_unit (
        .branch   (branch),
        .funct3   (imem_instr[14:12]),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .taken    (branch_taken)
    );

    // PC next logic
    wire [31:0] branch_target, jump_target, jalr_target;
    assign branch_target = pc_current + imm;
    assign jump_target   = pc_current + imm;
    assign jalr_target   = (rs1_data + imm) & 32'hFFFFFFFE;  // (rs1+imm) with LSB cleared per spec

    // AUIPC: pc + imm
    wire [31:0] auipc_result;
    assign auipc_result = pc_current + imm;

    // Override ALU result for AUIPC (uses PC not rs1)
    wire [31:0] actual_alu_result;
    assign actual_alu_result = (imem_instr[6:0] == 7'b0010111) ? auipc_result : alu_result;

    assign pc_next = (branch_taken) ? branch_target :
                     (jump && imem_instr[6:0] == 7'b1100111) ? jalr_target :  // JALR
                     (jump) ? jump_target :                                    // JAL
                     pc_plus4;

    // =========================================================================
    // MEM Stage — Memory Access
    // =========================================================================
    wire [31:0] mem_rd_data;
    assign mem_rd_data = dmem_rd_data;

    dmem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (actual_alu_result),
        .funct3    (imem_instr[14:12]),
        .wd_data   (rs2_data),
        .rd_data   (mem_rd_data)
    );

    // =========================================================================
    // WB Stage — Write Back
    // =========================================================================
    // JAL/JALR: write back pc+4 (link address) to rd
    wire is_jal_or_jalr;
    assign is_jal_or_jalr = (imem_instr[6:0] == 7'b1101111) ||   // JAL
                            (imem_instr[6:0] == 7'b1100111);     // JALR

    assign dmem_rd_data = is_jal_or_jalr ? pc_plus4 :
                          mem_to_reg     ? mem_rd_data :
                          actual_alu_result;

    // Outputs for observation
    assign reg_write_out = reg_write;
    assign mem_write_out = mem_write;

endmodule
