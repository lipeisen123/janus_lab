// Module Test: Immediate Generator — verifies all 5 immediate formats
module check_immgen;

    reg [6:0]  opcode;
    reg [31:0] instr;
    wire [31:0] imm;

    immgen dut (.opcode(opcode), .instr(instr), .imm(imm));

    integer passed, failed;

    // Helper: set instruction bits and opcode, then verify
    task check_fmt;
        input [6:0]  op;
        input [31:0] inst;
        input [31:0] expected;
        begin
            opcode = op; instr = inst; #1;
            if (imm !== expected) begin
                $error("[FAIL] op=%b instr=%h → imm=%h expected=%h", op, inst, imm, expected);
                failed = failed + 1;
            end else begin
                passed = passed + 1;
            end
        end
    endtask

    initial begin
        passed = 0; failed = 0;
        $display("=== Module Test: immgen (Immediate Generator) ===");

        // I-type: imm[11:0] at instr[31:20], sign-extended
        // Example: addi x1, x0, -1 → imm = -1 = 0xFFFFFFFF
        check_fmt(7'b0010011, 32'b111111111111_00000_000_00001_0010011, 32'hFFFF_FFFF);
        // Example: addi x1, x0, 2047 → imm = 2047 (max positive)
        check_fmt(7'b0010011, 32'b011111111111_00000_000_00001_0010011, 32'd2047);
        // Example: addi x1, x0, -2048 → imm = -2048 (min negative)
        check_fmt(7'b0010011, 32'b100000000000_00000_000_00001_0010011, -32'sd2048);

        // S-type: imm[11:5] at instr[31:25], imm[4:0] at instr[11:7]
        // sw x1, 8(x0) → imm = 8
        check_fmt(7'b0100011, {7'b0000000, 5'b00001, 5'b00000, 3'b010, 5'b01000, 7'b0100011}, 32'd8);
        // sw x1, -4(x0) → imm = -4
        check_fmt(7'b0100011, {7'b1111111, 5'b00001, 5'b00000, 3'b010, 5'b11100, 7'b0100011}, -32'sd4);

        // B-type: scrambled bits, LSB forced 0
        // beq x0, x0, 8 → imm = 8 (bit 0 = 0)
        check_fmt(7'b1100011, {1'b0, 6'b000000, 5'b00000, 5'b00000, 3'b000, 4'b0100, 1'b0, 7'b1100011}, 32'd8);
        // beq x0, x0, -4 → imm = -4
        check_fmt(7'b1100011, {1'b1, 6'b111111, 5'b00000, 5'b00000, 3'b000, 4'b1110, 1'b0, 7'b1100011}, -32'sd4);

        // U-type: imm[31:12] at instr[31:12], lower 12 bits zero
        // lui x1, 0x12345 → imm = 0x12345000
        check_fmt(7'b0110111, {20'h12345, 5'b00001, 7'b0110111}, 32'h12345000);

        // J-type: scrambled bits, LSB forced 0
        // jal x0, 12 → imm = 12
        check_fmt(7'b1101111, {1'b0, 6'b000000, 1'b0, 4'b0000, 1'b1, 8'b00000000, 7'b1101111}, 32'd12);

        $display("=== immgen: %0d passed, %0d failed ===", passed, failed);
        $finish;
    end

endmodule
