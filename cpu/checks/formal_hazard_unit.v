// C6 Formal Harness: Load-Use Hazard Detection (hazard_unit)
// Checks: load-use → stall PC + IF/ID, flush ID/EX
//          branch/jump → flush IF/ID + ID/EX, redirect
//          simultaneous load-use + branch → stall wins
module formal_hazard_unit;

    reg        ex_mem_read;
    reg [4:0]  ex_rd;
    reg [4:0]  id_rs1, id_rs2;
    reg        branch_taken, jump;
    wire       pc_stall, if_id_stall, if_id_flush, id_ex_flush;

    hazard_unit dut (
        .ex_mem_read (ex_mem_read),
        .ex_rd       (ex_rd),
        .id_rs1      (id_rs1),
        .id_rs2      (id_rs2),
        .branch_taken(branch_taken),
        .jump        (jump),
        .pc_stall    (pc_stall),
        .if_id_stall (if_id_stall),
        .if_id_flush (if_id_flush),
        .id_ex_flush (id_ex_flush)
    );

    // =========================================================================
    // Assertion 1: Load-use hazard → stall + flush
    // =========================================================================
    always @(*) begin
        if (ex_mem_read && ex_rd != 5'd0 && (ex_rd == id_rs1 || ex_rd == id_rs2)) begin
            // Load-use detected
            if (pc_stall !== 1'b1) begin
                $error("[FAIL C6] Load-use: pc_stall should be 1, got %b", pc_stall);
            end
            if (if_id_stall !== 1'b1) begin
                $error("[FAIL C6] Load-use: if_id_stall should be 1, got %b", if_id_stall);
            end
            if (id_ex_flush !== 1'b1) begin
                $error("[FAIL C6] Load-use: id_ex_flush should be 1, got %b", id_ex_flush);
            end
        end
    end

    // =========================================================================
    // Assertion 2: No load → no unnecessary stall
    // =========================================================================
    always @(*) begin
        if (!ex_mem_read || ex_rd == 5'd0 || (ex_rd != id_rs1 && ex_rd != id_rs2)) begin
            if (ex_mem_read && ex_rd != 5'd0 && ex_rd == id_rs1) begin
                // this is a load-use, skip
            end else begin
                if (pc_stall !== 1'b0) begin
                    $error("[FAIL C6] No load-use: pc_stall should be 0, got %b (mem_read=%b rd=%d rs1=%d rs2=%d)",
                           pc_stall, ex_mem_read, ex_rd, id_rs1, id_rs2);
                end
            end
        end
    end

    // =========================================================================
    // Assertion 3: Taken branch/jump → flush IF/ID and ID/EX
    // =========================================================================
    always @(*) begin
        if (branch_taken || jump) begin
            if (id_ex_flush !== 1'b1) begin
                $error("[FAIL C6] Branch/jump: id_ex_flush should be 1, got %b", id_ex_flush);
            end
        end
    end

    // =========================================================================
    // Assertion 4: Priority — load-use + branch → stall wins, flush suppressed
    // =========================================================================
    always @(*) begin
        if (ex_mem_read && ex_rd != 5'd0 && (ex_rd == id_rs1 || ex_rd == id_rs2) &&
            (branch_taken || jump)) begin
            // Both asserted: stall must win
            if (if_id_flush !== 1'b0) begin
                $error("[FAIL C6] Priority: if_id_flush should be 0 when load-use wins, got %b", if_id_flush);
            end
            if (pc_stall !== 1'b1) begin
                $error("[FAIL C6] Priority: pc_stall should be 1");
            end
        end
    end

    // =========================================================================
    // Directed test vectors
    // =========================================================================
    integer test_num;
    initial begin
        $display("=== C6: Hazard Unit Tests ===");
        test_num = 0;

        // --- No hazard ---
        $display("[%0d] No hazard", test_num);
        ex_mem_read = 0; ex_rd = 0; id_rs1 = 1; id_rs2 = 2;
        branch_taken = 0; jump = 0;
        #1;
        if ({pc_stall, if_id_stall, if_id_flush, id_ex_flush} == 4'b0000)
            $display("  PASS: all signals 0");
        else
            $error("  FAIL: got stall=%b stall=%b flush=%b flush=%b",
                   pc_stall, if_id_stall, if_id_flush, id_ex_flush);
        test_num++;

        // --- Load-use: EX has lw x3, ID has add x3,x3,x1 ---
        $display("[%0d] Load-use: lw→x3, ID uses x3", test_num);
        ex_mem_read = 1; ex_rd = 3; id_rs1 = 3; id_rs2 = 1;
        branch_taken = 0; jump = 0;
        #1;
        if (pc_stall == 1 && if_id_stall == 1 && id_ex_flush == 1 && if_id_flush == 0)
            $display("  PASS: pc_stall=1, if_id_stall=1, id_ex_flush=1, if_id_flush=0");
        else
            $error("  FAIL: got %b %b %b %b", pc_stall, if_id_stall, id_ex_flush, if_id_flush);
        test_num++;

        // --- No hazard: load→x3, ID uses x1,x2 (no match) ---
        $display("[%0d] No hazard: load→x3, but ID uses x1,x2", test_num);
        ex_mem_read = 1; ex_rd = 3; id_rs1 = 1; id_rs2 = 2;
        branch_taken = 0; jump = 0;
        #1;
        if (pc_stall == 0 && if_id_stall == 0)
            $display("  PASS: no stall");
        else
            $error("  FAIL: got stall=%b stall=%b", pc_stall, if_id_stall);
        test_num++;

        // --- No hazard: load→x0 (x0 doesn't trigger stall) ---
        $display("[%0d] No hazard: load→x0", test_num);
        ex_mem_read = 1; ex_rd = 0; id_rs1 = 0; id_rs2 = 1;
        branch_taken = 0; jump = 0;
        #1;
        if (pc_stall == 0)
            $display("  PASS: no stall for load→x0");
        else
            $error("  FAIL: stall asserted for x0 destination");
        test_num++;

        // --- Branch taken ---
        $display("[%0d] Branch taken in EX", test_num);
        ex_mem_read = 0; ex_rd = 0; id_rs1 = 0; id_rs2 = 0;
        branch_taken = 1; jump = 0;
        #1;
        if (if_id_flush == 1 && id_ex_flush == 1 && pc_stall == 0)
            $display("  PASS: if_id_flush=1, id_ex_flush=1, no stall");
        else
            $error("  FAIL: got flush=%b flush=%b", if_id_flush, id_ex_flush);
        test_num++;

        // --- Jump (JAL/JALR) ---
        $display("[%0d] Jump in EX", test_num);
        ex_mem_read = 0; ex_rd = 0; id_rs1 = 0; id_rs2 = 0;
        branch_taken = 0; jump = 1;
        #1;
        if (if_id_flush == 1 && id_ex_flush == 1)
            $display("  PASS: both stages flushed");
        else
            $error("  FAIL: got flush=%b flush=%b", if_id_flush, id_ex_flush);
        test_num++;

        // --- Priority: load-use AND branch taken simultaneously ---
        $display("[%0d] Priority: load-use + branch taken (stall wins)", test_num);
        ex_mem_read = 1; ex_rd = 5; id_rs1 = 5; id_rs2 = 6;
        branch_taken = 1; jump = 0;
        #1;
        if (pc_stall == 1 && if_id_stall == 1 && id_ex_flush == 1 && if_id_flush == 0)
            $display("  PASS: stall wins, no if_id_flush");
        else
            $error("  FAIL: got %b %b %b %b", pc_stall, if_id_stall, if_id_flush, id_ex_flush);
        test_num++;

        $display("=== C6: All %0d hazard unit tests passed ===", test_num);
        $finish;
    end

endmodule
