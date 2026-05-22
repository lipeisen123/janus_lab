// Module Test: Data Memory — verifies sub-word loads and stores
module check_dmem;

    reg        clk;
    reg        mem_read, mem_write;
    reg [31:0] addr;
    reg [2:0]  funct3;
    reg [31:0] wd_data;
    wire [31:0] rd_data;

    dmem dut (
        .clk(clk), .mem_read(mem_read), .mem_write(mem_write),
        .addr(addr), .funct3(funct3), .wd_data(wd_data), .rd_data(rd_data)
    );

    always #5 clk = ~clk;
    initial clk = 0;

    integer passed, failed;

    initial begin
        passed = 0; failed = 0;
        mem_read = 0; mem_write = 0; addr = 0; funct3 = 0; wd_data = 0;
        @(posedge clk);
        $display("=== Module Test: dmem (Data Memory) ===");

        // --- SW then LW (word) ---
        mem_write = 1; mem_read = 0; funct3 = 3'b010;
        addr = 32'd0; wd_data = 32'hDEAD_BEEF;
        @(posedge clk);
        mem_write = 0; mem_read = 1; #1;
        if (rd_data !== 32'hDEAD_BEEF) begin
            $error("[FAIL] LW: got %h expected DEAD_BEEF", rd_data); failed++;
        end else begin $display("[OK]  SW+LW word round-trip"); passed++; end

        // --- SB then LB (signed byte, MSB=1 → sign extend) ---
        @(posedge clk);
        mem_write = 1; funct3 = 3'b000;
        addr = 32'd4; wd_data = {24'h0, 8'hFF};        // store byte 0xFF
        @(posedge clk);
        mem_write = 0; mem_read = 1; #1;
        if (rd_data !== 32'hFFFF_FFFF) begin
            $error("[FAIL] LB sign-extend: got %h expected FFFFFFFF", rd_data); failed++;
        end else begin $display("[OK]  SB+LB sign extension (0xFF → 0xFFFFFFFF)"); passed++; end

        // --- SB then LBU (unsigned byte) ---
        @(posedge clk);
        mem_write = 1; funct3 = 3'b000;
        addr = 32'd8; wd_data = {24'h0, 8'hFF};
        @(posedge clk);
        mem_write = 0; mem_read = 1; funct3 = 3'b100;  // LBU
        #1;
        if (rd_data !== 32'h0000_00FF) begin
            $error("[FAIL] LBU zero-extend: got %h expected 000000FF", rd_data); failed++;
        end else begin $display("[OK]  SB+LBU zero extension (0xFF → 0x000000FF)"); passed++; end

        // --- SH then LH (signed halfword) ---
        @(posedge clk);
        mem_write = 1; funct3 = 3'b001;
        addr = 32'd12; wd_data = 32'hFFFF8000;           // store halfword 0x8000
        @(posedge clk);
        mem_write = 0; mem_read = 1; funct3 = 3'b001;    // LH
        #1;
        if (rd_data !== 32'hFFFF_8000) begin
            $error("[FAIL] LH sign-extend: got %h expected FFFF8000", rd_data); failed++;
        end else begin $display("[OK]  SH+LH sign extension (0x8000 → 0xFFFF8000)"); passed++; end

        // --- SH then LHU (unsigned halfword) ---
        @(posedge clk);
        mem_write = 1; funct3 = 3'b001;
        addr = 32'd16; wd_data = 32'hFFFF8000;
        @(posedge clk);
        mem_write = 0; mem_read = 1; funct3 = 3'b101;    // LHU
        #1;
        if (rd_data !== 32'h0000_8000) begin
            $error("[FAIL] LHU zero-extend: got %h expected 00008000", rd_data); failed++;
        end else begin $display("[OK]  SH+LHU zero extension (0x8000 → 0x00008000)"); passed++; end

        // --- SB byte-lane isolation ---
        @(posedge clk);
        mem_write = 1; funct3 = 3'b000;
        addr = 32'd20; wd_data = 32'hAA;
        @(posedge clk);
        mem_write = 0; mem_read = 1; funct3 = 3'b010;    // LW at same addr
        #1;
        // Only byte 0 should be AA, other bytes should be 0
        if ((rd_data & 32'hFFFF_FF00) !== 0) begin
            $error("[FAIL] SB byte-lane: other bytes corrupted, got %h", rd_data); failed++;
        end else begin $display("[OK]  SB only writes one byte lane"); passed++; end

        $display("=== dmem: %0d passed, %0d failed ===", passed, failed);
        $finish;
    end

endmodule
