// 5-Stage Pipelined RISC-V CPU (Phase 2)
// IF → ID → EX → MEM → WB with forwarding, hazard detection, stall, and flush
module cpu_pipelined (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] pc_current,
    output wire [31:0] instr_debug,
    output wire [31:0] alu_result_debug,
    output wire [31:0] wb_data_debug,
    output wire        reg_write_debug
);

    // =========================================================================
    // IF Stage — Instruction Fetch
    // =========================================================================
    wire [31:0] pc_next, pc_plus4;
    wire [31:0] if_instr;

    assign pc_plus4 = pc_current + 32'd4;

    pc u_pc (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_stall   (pc_stall),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    imem u_imem (
        .addr  (pc_current),
        .instr (if_instr)
    );

    // =========================================================================
    // IF/ID Pipeline Register
    // =========================================================================
    wire [31:0] id_pc, id_instr;

    if_id_reg u_if_id (
        .clk      (clk),
        .rst_n    (rst_n),
        .stall    (if_id_stall),
        .flush    (if_id_flush),
        .pc_in    (pc_current),      // actual instruction PC
        .instr_in (if_instr),
        .pc_out   (id_pc),
        .instr_out(id_instr)
    );

    assign instr_debug = id_instr;

    // =========================================================================
    // ID Stage — Decode & Register Read
    // =========================================================================
    wire [31:0] id_rs1_data, id_rs2_data;
    wire [31:0] id_imm;

    regfile u_regfile (
        .clk       (clk),
        .reg_write (wb_reg_write),
        .rs1       (id_instr[19:15]),
        .rs2       (id_instr[24:20]),
        .rd        (wb_rd),
        .rd_data   (wb_rd_data),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    immgen u_immgen (
        .opcode (id_instr[6:0]),
        .instr  (id_instr),
        .imm    (id_imm)
    );

    wire        id_reg_write, id_alu_src, id_mem_read, id_mem_write, id_mem_to_reg, id_branch, id_jump;
    wire [1:0]  id_alu_op;

    ctrl u_ctrl (
        .opcode     (id_instr[6:0]),
        .reg_write  (id_reg_write),
        .alu_src    (id_alu_src),
        .alu_op     (id_alu_op),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .jump       (id_jump)
    );

    // =========================================================================
    // ID/EX Pipeline Register
    // =========================================================================
    wire        ex_reg_write, ex_alu_src, ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_branch, ex_jump;
    wire [1:0]  ex_alu_op;
    wire [31:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm;
    wire [2:0]  ex_funct3;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [6:0]  ex_funct7;
    wire [6:0]  ex_opcode;
    wire [31:0] ex_instr;

    id_ex_reg u_id_ex (
        .clk           (clk),
        .rst_n         (rst_n),
        .flush         (id_ex_flush),
        .reg_write_in  (id_reg_write),
        .alu_src_in    (id_alu_src),
        .alu_op_in     (id_alu_op),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .branch_in     (id_branch),
        .jump_in       (id_jump),
        .pc_in         (id_pc),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .imm_in        (id_imm),
        .funct3_in     (id_instr[14:12]),
        .rs1_in        (id_instr[19:15]),
        .rs2_in        (id_instr[24:20]),
        .rd_in         (id_instr[11:7]),
        .funct7_in     (id_instr[31:25]),
        .opcode_in     (id_instr[6:0]),
        .instr_in      (id_instr),

        .reg_write_out  (ex_reg_write),
        .alu_src_out    (ex_alu_src),
        .alu_op_out     (ex_alu_op),
        .mem_read_out   (ex_mem_read),
        .mem_write_out  (ex_mem_write),
        .mem_to_reg_out (ex_mem_to_reg),
        .branch_out     (ex_branch),
        .jump_out       (ex_jump),
        .pc_out         (ex_pc),
        .rs1_data_out   (ex_rs1_data),
        .rs2_data_out   (ex_rs2_data),
        .imm_out        (ex_imm),
        .funct3_out     (ex_funct3),
        .rs1_out        (ex_rs1),
        .rs2_out        (ex_rs2),
        .rd_out         (ex_rd),
        .funct7_out     (ex_funct7),
        .opcode_out     (ex_opcode),
        .instr_out      (ex_instr)
    );

    // =========================================================================
    // EX Stage — Execute
    // =========================================================================

    // --- Forwarding Muxes ---
    wire [31:0] ex_alu_a_muxed, ex_alu_b_muxed;

    // Forward A mux: 2'b00=regfile, 2'b10=EX/MEM, 2'b01=MEM/WB
    assign ex_alu_a_muxed = (forward_a == 2'b10) ? mem_alu_result :
                            (forward_a == 2'b01) ? wb_rd_data    :
                            ex_rs1_data;

    // Forward B mux
    wire [31:0] ex_rs2_forwarded;
    assign ex_rs2_forwarded = (forward_b == 2'b10) ? mem_alu_result :
                              (forward_b == 2'b01) ? wb_rd_data    :
                              ex_rs2_data;

    // ALU input B: immediate or forwarded rs2
    assign ex_alu_b_muxed = ex_alu_src ? ex_imm : ex_rs2_forwarded;

    // --- ALU Control ---
    wire [3:0] ex_alu_ctrl;
    aluctrl u_aluctrl (
        .alu_op   (ex_alu_op),
        .funct3   (ex_funct3),
        .funct7_5 (ex_funct7[5]),
        .alu_ctrl (ex_alu_ctrl)
    );

    // --- ALU ---
    wire [31:0] ex_alu_result;
    wire        ex_zero;

    alu u_alu (
        .a        (ex_alu_a_muxed),
        .b        (ex_alu_b_muxed),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .zero     (ex_zero)
    );

    // --- Branch Unit ---
    wire ex_branch_taken;
    branch_unit u_branch_unit (
        .branch   (ex_branch),
        .funct3   (ex_funct3),
        .rs1_data (ex_alu_a_muxed),
        .rs2_data (ex_alu_b_muxed),
        .taken    (ex_branch_taken)
    );

    // --- PC Target Calculation ---
    wire [31:0] ex_branch_target, ex_jump_target, ex_jalr_target;
    assign ex_branch_target = ex_pc + ex_imm;     // PC-relative (from ID stage PC+4)
    assign ex_jump_target   = ex_pc + ex_imm;     // JAL target
    assign ex_jalr_target   = (ex_alu_a_muxed + ex_imm) & 32'hFFFFFFFE;  // JALR: (rs1+imm) with LSB cleared

    // --- AUIPC: override ALU result with PC + imm ---
    // JAL/JALR: write back pc+4 (link address) to rd
    wire [31:0] ex_actual_alu_result;
    assign ex_actual_alu_result = (ex_opcode == 7'b0010111) ? (ex_pc + ex_imm) :           // AUIPC
                                  (ex_opcode == 7'b1101111 || ex_opcode == 7'b1100111) ? (ex_pc + 32'd4) :  // JAL/JALR link
                                  ex_alu_result;

    // --- PC Next (redirect on branch taken or jump) ---
    // Branch (B-type): PC + imm (ex_branch_target = ex_pc + ex_imm)
    // JAL (J-type):    PC + imm (same computation = ex_pc + ex_imm)
    // JALR (I-type):   (rs1 + imm) & ~1
    wire pc_take_redirect;
    assign pc_take_redirect = ex_branch_taken || ex_jump;

    wire [31:0] ex_redirect_target;
    assign ex_redirect_target = ex_branch_taken ? ex_branch_target :
                                (ex_opcode == 7'b1100111) ? ex_jalr_target :
                                ex_jump_target;  // JAL

    assign pc_next = pc_take_redirect ? ex_redirect_target : pc_plus4;

    // =========================================================================
    // EX/MEM Pipeline Register
    // =========================================================================
    wire        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;
    wire [31:0] mem_alu_result, mem_rs2_data;
    wire [4:0]  mem_rd;
    wire [2:0]  mem_funct3;
    wire        mem_branch_taken, mem_jump;
    wire [31:0] mem_pc_target;

    ex_mem_reg u_ex_mem (
        .clk              (clk),
        .rst_n            (rst_n),
        .reg_write_in     (ex_reg_write),
        .mem_read_in      (ex_mem_read),
        .mem_write_in     (ex_mem_write),
        .mem_to_reg_in    (ex_mem_to_reg),
        .alu_result_in    (ex_actual_alu_result),
        .rs2_data_in      (ex_rs2_forwarded),
        .rd_in            (ex_rd),
        .funct3_in        (ex_funct3),
        .branch_taken_in  (ex_branch_taken),
        .jump_in          (ex_jump),
        .pc_target_in     (ex_pc_target),

        .reg_write_out     (mem_reg_write),
        .mem_read_out      (mem_mem_read),
        .mem_write_out     (mem_mem_write),
        .mem_to_reg_out    (mem_mem_to_reg),
        .alu_result_out    (mem_alu_result),
        .rs2_data_out      (mem_rs2_data),
        .rd_out            (mem_rd),
        .funct3_out        (mem_funct3),
        .branch_taken_out  (mem_branch_taken),
        .jump_out          (mem_jump),
        .pc_target_out     (mem_pc_target)
    );

    // =========================================================================
    // MEM Stage — Memory Access
    // =========================================================================
    wire [31:0] mem_rd_data;

    dmem u_dmem (
        .clk       (clk),
        .mem_read  (mem_mem_read),
        .mem_write (mem_mem_write),
        .addr      (mem_alu_result),
        .funct3    (mem_funct3),
        .wd_data   (mem_rs2_data),
        .rd_data   (mem_rd_data)
    );

    // =========================================================================
    // MEM/WB Pipeline Register
    // =========================================================================
    wire        wb_reg_write, wb_mem_to_reg;
    wire [31:0] wb_alu_result, wb_mem_rd_data;
    wire [4:0]  wb_rd;

    mem_wb_reg u_mem_wb (
        .clk             (clk),
        .rst_n           (rst_n),
        .reg_write_in    (mem_reg_write),
        .mem_to_reg_in   (mem_mem_to_reg),
        .alu_result_in   (mem_alu_result),
        .mem_rd_data_in  (mem_rd_data),
        .rd_in           (mem_rd),

        .reg_write_out   (wb_reg_write),
        .mem_to_reg_out  (wb_mem_to_reg),
        .alu_result_out  (wb_alu_result),
        .mem_rd_data_out (wb_mem_rd_data),
        .rd_out          (wb_rd)
    );

    // =========================================================================
    // WB Stage — Write Back
    // =========================================================================
    wire [31:0] wb_rd_data;
    assign wb_rd_data = wb_mem_to_reg ? wb_mem_rd_data : wb_alu_result;

    // =========================================================================
    // Hazard Unit — stall/flush signals
    // =========================================================================
    wire pc_stall, if_id_stall, if_id_flush, id_ex_flush;

    hazard_unit u_hazard_unit (
        .ex_mem_read  (ex_mem_read),
        .ex_rd        (ex_rd),
        .id_rs1       (id_instr[19:15]),
        .id_rs2       (id_instr[24:20]),
        .branch_taken (ex_branch_taken),
        .jump         (ex_jump),
        .pc_stall     (pc_stall),
        .if_id_stall  (if_id_stall),
        .if_id_flush  (if_id_flush),
        .id_ex_flush  (id_ex_flush)
    );

    // =========================================================================
    // Forwarding Unit
    // =========================================================================
    wire [1:0] forward_a, forward_b;

    forward_unit u_forward_unit (
        .mem_reg_write (mem_reg_write),
        .mem_rd        (mem_rd),
        .wb_reg_write  (wb_reg_write),
        .wb_rd         (wb_rd),
        .ex_rs1        (ex_rs1),
        .ex_rs2        (ex_rs2),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );

    // =========================================================================
    // Debug outputs
    // =========================================================================
    assign alu_result_debug = ex_actual_alu_result;
    assign wb_data_debug    = wb_rd_data;
    assign reg_write_debug  = wb_reg_write;

endmodule
