/*
 * tb_top — Top-Level Testbench
 *
 * Instantiates the cpu module and drives clock and reset to allow simulation.
 * The clock period is 10 ns (100 MHz). Reset is held low for the first four
 * clock cycles to ensure all pipeline registers and the PC are cleared before
 * any instruction is fetched. The testbench is intentionally minimal — it
 * provides infrastructure only. Individual test programs are loaded into the
 * instruction memory via the MEM_FILE parameter on imem and (optionally) a
 * data-memory image; pass-fail is determined by checking the register file or
 * data memory state at a known cycle count, or by having the test program write
 * a sentinel value to a magic address that the testbench monitors. Waveforms
 * are dumped to dump.vcd for post-simulation viewing in GTKWave or equivalent.
 */

`timescale 1ns/1ps

module tb_top;

    // -------------------------------------------------------------------------
    // Clock and reset
    // -------------------------------------------------------------------------
    reg clk;
    reg rst_n;

    localparam CLK_PERIOD = 10; // ns

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
    end

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    cpu u_cpu (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // -------------------------------------------------------------------------
    // Simulation control
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

    // Safety timeout — override per test as needed
    localparam MAX_CYCLES = 10_000;
    integer cycle_count;

    initial cycle_count = 0;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= MAX_CYCLES) begin
            $display("TIMEOUT: simulation exceeded %0d cycles", MAX_CYCLES);
            $finish;
        end
    end

    // -------------------------------------------------------------------------
    // Pass/fail monitor
    // Writes to address 0xFFFF_0000 are treated as test results:
    //   data == 1  -> PASS
    //   data == 0  -> FAIL
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (u_cpu.u_dmem.mem_write &&
            u_cpu.u_dmem.addr == 32'hFFFF_0000) begin
            if (u_cpu.u_dmem.wr_data == 32'd1)
                $display("PASS at cycle %0d", cycle_count);
            else
                $display("FAIL at cycle %0d (result=0x%08h)",
                         cycle_count, u_cpu.u_dmem.wr_data);
            $finish;
        end
    end

endmodule
