// Bug-Detection Testbench: catches BLT/BLTU swap in branch_unit
// Tests the case where signed and unsigned comparisons differ:
//   BLT  -1, 0  → signed: -1 < 0 = TRUE   (taken)
//   BLTU -1, 0  → unsigned: 0xFFFFFFFF < 0 = FALSE (not taken)
// The buggy unit gives the opposite result for both.
module tb_branch_bug_detect;

    reg        branch;
    reg [2:0]  funct3;
    reg [31:0] rs1_data, rs2_data;
    wire       taken;

    // Instantiate: use "branch_unit" for golden, "branch_unit_buggy" for buggy
`ifdef INJECT_BUG
    branch_unit_buggy dut (
`else
    branch_unit dut (
`endif
        .branch  (branch),
        .funct3  (funct3),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .taken   (taken)
    );

    integer failed, passed;

    initial begin
        failed = 0;
        passed = 0;

        // =========================================================================
        // Test 1: BLT -1 < 0  →  should be TAKEN (signed)
        // =========================================================================
        branch = 1; funct3 = 3'b100;    // BLT
        rs1_data = 32'hFFFF_FFFF;       // -1 (signed) = 0xFFFFFFFF
        rs2_data = 32'd0;
        #10;
        if (taken !== 1'b1) begin
            $display("[BUG] BLT -1 < 0: expected TAKEN, got NOT TAKEN");
            $display("  rs1=%h (signed %0d), rs2=%h (signed %0d)",
                     $signed(rs1_data), $signed(rs1_data),
                     $signed(rs2_data), $signed(rs2_data));
            $display("  Signed compare: %0d < %0d = TRUE  → should be taken",
                     $signed(rs1_data), $signed(rs2_data));
            $display("  Unsigned compare: %h < %h = FALSE → buggy unit uses this",
                     rs1_data, rs2_data);
            failed++;
        end else begin
            $display("[OK]  Test 1: BLT -1 < 0 = TAKEN (correct)");
            passed++;
        end

        // =========================================================================
        // Test 2: BLTU 0xFFFFFFFF < 0  →  should be NOT TAKEN (unsigned)
        // =========================================================================
        branch = 1; funct3 = 3'b110;    // BLTU
        rs1_data = 32'hFFFF_FFFF;       // 0xFFFFFFFF = 4294967295 (unsigned)
        rs2_data = 32'd0;
        #10;
        if (taken !== 1'b0) begin
            $display("[BUG] BLTU 0xFFFFFFFF < 0: expected NOT TAKEN, got TAKEN");
            $display("  rs1=%h (unsigned %0d), rs2=%h (unsigned %0d)",
                     rs1_data, rs1_data,
                     rs2_data, rs2_data);
            $display("  Unsigned compare: %0d < %0d = FALSE → should be not taken",
                     rs1_data, rs2_data);
            $display("  Signed compare: %0d < %0d = TRUE  → buggy unit uses this",
                     $signed(rs1_data), $signed(rs2_data));
            failed++;
        end else begin
            $display("[OK]  Test 2: BLTU 0xFFFFFFFF < 0 = NOT TAKEN (correct)");
            passed++;
        end

        // =========================================================================
        // Test 3: BLT 5 < 10  →  both signed and unsigned agree (= TAKEN)
        // This would NOT catch the bug, showing why good test vectors matter.
        // =========================================================================
        branch = 1; funct3 = 3'b100;    // BLT
        rs1_data = 32'd5;
        rs2_data = 32'd10;
        #10;
        if (taken !== 1'b1) begin
            $display("[BUG] BLT 5 < 10: expected TAKEN");
            failed++;
        end else begin
            $display("[OK]  Test 3: BLT 5 < 10 = TAKEN (both agree, not diagnostic)");
            passed++;
        end

        // =========================================================================
        // Test 4: Negative numbers — BLT -100 < 50 = TAKEN
        // =========================================================================
        branch = 1; funct3 = 3'b100;    // BLT
        rs1_data = -32'sd100;
        rs2_data = 32'd50;
        #10;
        if (taken !== 1'b1) begin
            $display("[BUG] BLT -100 < 50: expected TAKEN, got NOT TAKEN");
            $display("  Signed: %0d < %0d = TRUE  → should be taken",
                     $signed(rs1_data), $signed(rs2_data));
            $display("  Unsigned: %h < %h = FALSE → buggy result",
                     rs1_data, rs2_data);
            failed++;
        end else begin
            $display("[OK]  Test 4: BLT -100 < 50 = TAKEN (correct)");
            passed++;
        end

        // =========================================================================
        // Report
        // =========================================================================
        $display("================================================");
        if (failed > 0) begin
            $display("=== BUG DETECTED: %0d test(s) failed, %0d passed ===", failed, passed);
        end else begin
            $display("=== ALL %0d tests passed (golden unit) ===", passed);
        end
        $display("================================================");
        $display("Run with +define+INJECT_BUG to see the buggy behavior.");
        $finish;
    end

endmodule
