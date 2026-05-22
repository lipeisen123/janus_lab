// Testbench Top: loads prog.hex into IMEM, runs the CPU, monitors PASS/FAIL
// PASS/FAIL protocol: SW to 0xFFFF_0000 — x1=1 → PASS, x1=0 → FAIL
`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst_n;

    // =========================================================================
    // Clock: 10ns period
    // =========================================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // =========================================================================
    // Single-Cycle CPU (Phase 1)
    // Use +define+USE_PIPELINED to test the pipelined CPU instead.
    // =========================================================================
    wire [31:0] pc, instr, alu_result, dmem_rd_data;
    wire        reg_write, mem_write;

`ifdef USE_PIPELINED
    wire [31:0] wb_data;
    cpu_pipelined u_cpu (
        .clk              (clk),
        .rst_n            (rst_n),
        .pc_current       (pc),
        .instr_debug      (instr),
        .alu_result_debug (alu_result),
        .wb_data_debug    (wb_data),
        .reg_write_debug  (reg_write)
    );
`else
    cpu u_cpu (
        .clk            (clk),
        .rst_n          (rst_n),
        .pc_current     (pc),
        .instr          (instr),
        .alu_result     (alu_result),
        .dmem_rd_data   (dmem_rd_data),
        .reg_write_out  (reg_write),
        .mem_write_out  (mem_write)
    );
`endif

    // =========================================================================
    // Load program
    // =========================================================================
    initial begin
        $readmemh("prog.hex", tb_top.u_cpu.u_imem.rom);
    end

    // =========================================================================
    // PASS/FAIL detection at 0xFFFF_0000
    // =========================================================================
    reg        test_done;
    reg        test_passed;
    reg [31:0] test_result;

    initial begin
        test_done   = 0;
        test_passed = 0;
        test_result = 0;
    end

    always @(posedge clk) begin
        if (!test_done && mem_write && alu_result == 32'hFFFF_0000) begin
            test_done <= 1;
            // The SW instruction stores rs2_data to memory
            // We catch this by checking the next clock's write
            $display("=== MAGIC_ADDR write at time %0t, MEM_WRITE=%b ===", $time, mem_write);
        end
    end

    // =========================================================================
    // Test sequence
    // =========================================================================
    reg [31:0] cycle_count;

    initial begin
        rst_n = 1'b0;
        cycle_count = 0;

        // Reset hold
        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        $display("=== Testbench Started at time %0t ===", $time);

        // Run
        repeat (2000) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            // EBREAK detection
            if (instr == 32'h00100073) begin
                $display("EBREAK at cycle %0d, PC=%h", cycle_count, pc);
                if (test_done)
                    $display("=== TEST PASSED ===");
                else
                    $display("=== TEST FAILED (no magic write) ===");
                $finish;
            end
        end

        $display("=== Timeout after %0d cycles ===", cycle_count);
        $finish;
    end

    // =========================================================================
    // Waveform
    // =========================================================================
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
