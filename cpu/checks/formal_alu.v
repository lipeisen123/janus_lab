// C2 Formal Harness: ALU Operation Correctness
// Checks all 11 ALU operations against bit-vector semantics
module formal_alu;

    reg [31:0] a, b;
    reg [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    alu dut (
        .a       (a),
        .b       (b),
        .alu_ctrl(alu_ctrl),
        .result  (result),
        .zero    (zero)
    );

    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLL  = 4'd5;
    localparam ALU_SRL  = 4'd6;
    localparam ALU_SRA  = 4'd7;
    localparam ALU_SLT  = 4'd8;
    localparam ALU_SLTU = 4'd9;
    localparam ALU_PASS = 4'd10;

    wire [31:0] expected;
    wire        expected_zero;

    assign expected = (alu_ctrl == ALU_ADD)  ? (a + b) :
                      (alu_ctrl == ALU_SUB)  ? (a - b) :
                      (alu_ctrl == ALU_AND)  ? (a & b) :
                      (alu_ctrl == ALU_OR)   ? (a | b) :
                      (alu_ctrl == ALU_XOR)  ? (a ^ b) :
                      (alu_ctrl == ALU_SLL)  ? (a << b[4:0]) :
                      (alu_ctrl == ALU_SRL)  ? (a >> b[4:0]) :
                      (alu_ctrl == ALU_SRA)  ? ($signed(a) >>> b[4:0]) :
                      (alu_ctrl == ALU_SLT)  ? (($signed(a) < $signed(b)) ? 32'd1 : 32'd0) :
                      (alu_ctrl == ALU_SLTU) ? ((a < b) ? 32'd1 : 32'd0) :
                      (alu_ctrl == ALU_PASS) ? b :
                      32'bx;

    assign expected_zero = (expected == 32'd0);

    // =========================================================================
    // Assertion: result matches expected for all defined ALU codes
    // =========================================================================
    always @(*) begin
        if (result !== expected) begin
            $error("[FAIL C2] ALU op=%0d: a=%h b=%h → result=%h, expected=%h",
                   alu_ctrl, a, b, result, expected);
        end
        if (zero !== expected_zero) begin
            $error("[FAIL C2] ALU op=%0d: zero flag mismatch, got=%b expected=%b",
                   alu_ctrl, zero, expected_zero);
        end
    end

    // =========================================================================
    // Directed test vectors
    // =========================================================================
    integer test_num;
    initial begin
        $display("=== C2: ALU Operation Tests ===");
        test_num = 0;

        // ADD
        alu_ctrl = ALU_ADD;
        a = 32'd10;  b = 32'd20; #1;
        if (result == 32'd30 && zero == 0) $display("[%0d] ADD 10+20=30 PASS", test_num);
        else $error("[%0d] ADD FAIL: got %d", test_num, result);
        test_num++;

        a = 32'hFFFF_FFFF; b = 32'd1; #1;
        if (result == 32'd0 && zero == 1) $display("[%0d] ADD overflow wrap PASS", test_num);
        else $error("[%0d] ADD overflow FAIL: got %h", test_num, result);
        test_num++;

        // SUB
        alu_ctrl = ALU_SUB;
        a = 32'd20; b = 32'd5; #1;
        if (result == 32'd15 && zero == 0) $display("[%0d] SUB 20-5=15 PASS", test_num);
        else $error("[%0d] SUB FAIL: got %d", test_num, result);
        test_num++;

        a = 32'd5; b = 32'd5; #1;
        if (result == 32'd0 && zero == 1) $display("[%0d] SUB 5-5=0 zero=1 PASS", test_num);
        else $error("[%0d] SUB zero FAIL", test_num);
        test_num++;

        // AND
        alu_ctrl = ALU_AND;
        a = 32'hFF00_FF00; b = 32'hF0F0_F0F0; #1;
        if (result == 32'hF000_F000) $display("[%0d] AND PASS", test_num);
        else $error("[%0d] AND FAIL: got %h", test_num, result);
        test_num++;

        // OR
        alu_ctrl = ALU_OR;
        a = 32'hFF00_0000; b = 32'h00FF_0000; #1;
        if (result == 32'hFFFF_0000) $display("[%0d] OR PASS", test_num);
        else $error("[%0d] OR FAIL: got %h", test_num, result);
        test_num++;

        // XOR
        alu_ctrl = ALU_XOR;
        a = 32'hFFFF_0000; b = 32'hFFFF_FFFF; #1;
        if (result == 32'h0000_FFFF) $display("[%0d] XOR PASS", test_num);
        else $error("[%0d] XOR FAIL: got %h", test_num, result);
        test_num++;

        // SLL
        alu_ctrl = ALU_SLL;
        a = 32'd1; b = 32'd10; #1;
        if (result == 32'd1024) $display("[%0d] SLL 1<<10=1024 PASS", test_num);
        else $error("[%0d] SLL FAIL: got %d", test_num, result);
        test_num++;

        // SRL (logical)
        alu_ctrl = ALU_SRL;
        a = 32'h8000_0000; b = 32'd31; #1;
        if (result == 32'd1) $display("[%0d] SRL 0x80000000>>31=1 PASS", test_num);
        else $error("[%0d] SRL FAIL: got %h", test_num, result);
        test_num++;

        // SRA (arithmetic)
        alu_ctrl = ALU_SRA;
        a = 32'h8000_0000; b = 32'd31; #1;
        if (result == 32'hFFFF_FFFF) $display("[%0d] SRA 0x80000000>>>31=0xFFFFFFFF PASS", test_num);
        else $error("[%0d] SRA FAIL: got %h", test_num, result);
        test_num++;

        // SLT (signed)
        alu_ctrl = ALU_SLT;
        a = 32'hFFFF_FFFF; b = 32'd0; #1;     // -1 < 0
        if (result == 32'd1) $display("[%0d] SLT -1<0=1 PASS", test_num);
        else $error("[%0d] SLT FAIL: got %d", test_num, result);
        test_num++;

        a = 32'd5; b = 32'd3; #1;
        if (result == 32'd0) $display("[%0d] SLT 5<3=0 PASS", test_num);
        else $error("[%0d] SLT FAIL: got %d", test_num, result);
        test_num++;

        // SLTU (unsigned)
        alu_ctrl = ALU_SLTU;
        a = 32'hFFFF_FFFF; b = 32'd0; #1;     // 2^32-1 > 0
        if (result == 32'd0) $display("[%0d] SLTU 0xFFFFFFFF<0=0 PASS", test_num);
        else $error("[%0d] SLTU FAIL: got %d", test_num, result);
        test_num++;

        // PASS (LUI)
        alu_ctrl = ALU_PASS;
        a = 32'h1234_5678; b = 32'hABCD_0000; #1;
        if (result == b) $display("[%0d] PASS (LUI) = b PASS", test_num);
        else $error("[%0d] PASS FAIL: got %h expected %h", test_num, result, b);
        test_num++;

        $display("=== C2: All %0d ALU tests passed ===", test_num);
        $finish;
    end

endmodule
