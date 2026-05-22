// C1 Formal Harness: Register x0 Hardwired to Zero (regfile)
// Checks: x0 reads return 0, writes to x0 are silently ignored
module formal_regfile_x0;

    reg clk;
    reg        reg_write;
    reg [4:0]  rs1, rs2, rd;
    reg [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    regfile dut (
        .clk      (clk),
        .reg_write(reg_write),
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (rd),
        .rd_data  (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // Clock
    always #5 clk = ~clk;
    initial clk = 0;

    // =========================================================================
    // Assertion 1: rs1 == 0 → rs1_data == 0 (combinational)
    // =========================================================================
    always @(*) begin
        if (rs1 == 5'd0) begin
            if (rs1_data !== 32'd0) begin
                $error("[FAIL C1] x0 read on rs1 returned %h, expected 0", rs1_data);
                $stop;
            end
        end
    end

    // =========================================================================
    // Assertion 2: rs2 == 0 → rs2_data == 0 (combinational)
    // =========================================================================
    always @(*) begin
        if (rs2 == 5'd0) begin
            if (rs2_data !== 32'd0) begin
                $error("[FAIL C1] x0 read on rs2 returned %h, expected 0", rs2_data);
                $stop;
            end
        end
    end

    // =========================================================================
    // Assertion 3: Write to x0 does not change x0's read value
    // =========================================================================
    reg [31:0] x0_before_write;
    reg        writing_to_x0;

    always @(negedge clk) begin
        writing_to_x0 <= reg_write && (rd == 5'd0);
        x0_before_write <= rs1_data;     // capture x0 before write (rs1 == 0)
    end

    always @(negedge clk) begin
        if ($past(reg_write && rd == 5'd0)) begin
            // After a write to x0, x0 must still be 0
            // (force rs1=0 for the check)
            if (dut.regs[0] !== 32'd0) begin
                $error("[FAIL C1] Write to x0 changed internal regs[0] to %h", dut.regs[0]);
                $stop;
            end
        end
    end

    // =========================================================================
    // Test sequence: drive all relevant combinations
    // =========================================================================
    integer test_num;
    initial begin
        test_num = 0;
        reg_write = 0;
        rs1 = 0; rs2 = 0; rd = 0; rd_data = 0;
        @(posedge clk);

        // Test 1: rs1 = x0, reads should return 0
        $display("[C1 Test %0d] rs1=x0 read check", test_num);
        rs1 = 0; rs2 = 1; #1;
        if (rs1_data !== 0) $error("FAIL: rs1=x0 returned %h", rs1_data);
        else $display("  PASS: rs1=x0 returned 0");
        test_num++;

        // Test 2: rs2 = x0, reads should return 0
        $display("[C1 Test %0d] rs2=x0 read check", test_num);
        rs1 = 1; rs2 = 0; #1;
        if (rs2_data !== 0) $error("FAIL: rs2=x0 returned %h", rs2_data);
        else $display("  PASS: rs2=x0 returned 0");
        test_num++;

        // Test 3: Write non-zero to x1, read back
        $display("[C1 Test %0d] Write x1=0xDEAD, read back", test_num);
        @(posedge clk);
        reg_write = 1; rd = 1; rd_data = 32'hDEAD_BEEF; rs1 = 1; rs2 = 0;
        @(posedge clk);
        reg_write = 0; #1;
        if (rs1_data !== 32'hDEAD_BEEF) $error("FAIL: x1 readback %h", rs1_data);
        else $display("  PASS: x1 = 0xDEAD_BEEF");
        test_num++;

        // Test 4: Write non-zero to x0, verify writes ignored + reads still 0
        $display("[C1 Test %0d] Write x0=0xCAFE (should be ignored)", test_num);
        @(posedge clk);
        reg_write = 1; rd = 0; rd_data = 32'hCAFE_0000;
        @(posedge clk);
        reg_write = 0; rs1 = 0; #1;
        if (rs1_data !== 0) $error("FAIL: x0 read after write returned %h", rs1_data);
        else $display("  PASS: x0 still reads 0 after attempted write");
        test_num++;

        // Test 5: Read-during-write forwarding on x1, but NOT on x0
        // Write x1=0xAAAA, read x1 in same cycle — should forward
        $display("[C1 Test %0d] RDW: write x1, read in same cycle", test_num);
        reg_write = 1; rd = 1; rd_data = 32'hAAAA_BBBB; rs1 = 1; rs2 = 0; #1;
        if (rs1_data !== 32'hAAAA_BBBB) $error("FAIL: RDW forwarding on x1");
        else $display("  PASS: RDW forwarding works on x1");
        test_num++;

        // Test 6: RDW on x0 should still return 0 (NOT the written value)
        $display("[C1 Test %0d] RDW: write x0, read in same cycle — must return 0", test_num);
        reg_write = 1; rd = 0; rd_data = 32'h5555_5555; rs1 = 0; rs2 = 0; #1;
        if (rs1_data !== 0) $error("FAIL: RDW on x0 forwarded %h instead of 0", rs1_data);
        else $display("  PASS: RDW on x0 correctly returns 0");
        test_num++;

        $display("=== C1: All x0 checks passed ===");
        $finish;
    end

endmodule
