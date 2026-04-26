module top_cpu (
    input  logic        clk,
    input  logic        rst_n
);
    // 控制信号
    logic        reg_write, mem_read, mem_write, alu_src, mem_to_reg, branch, jump;
    logic [1:0]  alu_op;
    logic [3:0]  alu_control;
    logic [31:0] imm, alu_res, rdata1, rdata2, wb_data, next_pc, pc_plus4;
    logic        alu_zero;

    // 1. PC & 取指
    pc_reg u_pc (.clk, .rst_n, .next_pc, .pc);
    imem   u_imem(.addr(pc), .instr);

    // 2. 控制与立即数
    ctrl     u_ctrl    (.opcode(instr[6:0]), .reg_write, .mem_read, .mem_write, 
                        .alu_src, .mem_to_reg, .branch, .jump, .alu_op);
    imm_gen  u_imm     (.instr, .imm);
    alu_ctrl u_alu_ctrl(.alu_op, .funct3(instr[14:12]), .funct7(instr[31:25]), 
                        .alu_control);

    // 3. 寄存器堆读
    regfile u_regfile (.clk, .we3(reg_write), .rs1(instr[19:15]), .rs2(instr[24:20]), 
                       .rd(instr[11:7]), .wdata3(wb_data), .rdata1, .rdata2);

    // 4. ALU 操作数选择
    logic [31:0] alu_b = alu_src ? imm : rdata2;
    
    // 5. ALU 计算
    alu u_alu (.a(rdata1), .b(alu_b), .ctrl(alu_control), .res(alu_res), .zero(alu_zero));

    // 6. 数据存储器
    dmem u_dmem (.clk, .mem_read, .mem_write, .addr(alu_res), 
                 .wdata(rdata2), .rdata);

    // 7. 写回多路选择器
    assign wb_data = mem_to_reg ? rdata : alu_res;

    // 8. PC 下一值逻辑 (分支/跳转/顺序)
    assign pc_plus4 = pc + 32'h4;
    logic [31:0] branch_target = pc_plus4 + imm;
    logic [31:0] jump_reg_target = rdata1 + imm; // JALR
    logic [31:0] jump_target     = pc_plus4 + imm; // JAL / JALR PC相对部分
    
    always_comb begin
        if (jump) begin
            next_pc = (instr[6:0] == 7'b1100111) ? (jump_reg_target & 32'hFFFFFFFE) : jump_target;
        end else if (branch & alu_zero) begin
            next_pc = branch_target;
        end else begin
            next_pc = pc_plus4;
        end
    end

    // 仿真打印 (可选)
    // initial $monitor("T=%0t PC=%h Instr=%h Reg[rd]=%h", $time, pc, instr, wb_data);
endmodule
