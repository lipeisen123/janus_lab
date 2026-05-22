// Module Test: Control Unit — verifies all 9 opcodes produce correct control signals
module check_ctrl;

    reg [6:0] opcode;
    wire      reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump;
    wire [1:0] alu_op;

    ctrl dut (
        .opcode    (opcode),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .alu_op    (alu_op),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump)
    );

    integer passed, failed;

    initial begin
        passed = 0; failed = 0;
        $display("=== Module Test: ctrl (Control Unit) ===");

        // R-type (0110011)
        opcode = 7'b0110011; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b0, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] R-type: got reg_w=%b as=%b aop=%b mr=%b mw=%b m2r=%b br=%b j=%b", reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump); failed++; end

        // I-type ALU (0010011)
        opcode = 7'b0010011; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] I-ALU"); failed++; end

        // Load (0000011)
        opcode = 7'b0000011; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b1, 2'b00, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] Load"); failed++; end

        // Store (0100011)
        opcode = 7'b0100011; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b0, 1'b1, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] Store"); failed++; end

        // Branch (1100011)
        opcode = 7'b1100011; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b0, 1'b0, 2'b01, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0})
            passed++; else begin $error("[FAIL] Branch"); failed++; end

        // LUI (0110111)
        opcode = 7'b0110111; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] LUI"); failed++; end

        // AUIPC (0010111)
        opcode = 7'b0010111; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0})
            passed++; else begin $error("[FAIL] AUIPC"); failed++; end

        // JAL (1101111)
        opcode = 7'b1101111; #1;
        if ({reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1})
            passed++; else begin $error("[FAIL] JAL"); failed++; end

        // JALR (1100111)
        opcode = 7'b1100111; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == {1'b1, 1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1})
            passed++; else begin $error("[FAIL] JALR"); failed++; end

        // Illegal opcode → all zero
        opcode = 7'b1111111; #1;
        if ({reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} == 9'b0)
            passed++; else begin $error("[FAIL] Illegal opcode should be NOP"); failed++; end

        $display("=== ctrl: %0d passed, %0d failed ===", passed, failed);
        $finish;
    end

endmodule
