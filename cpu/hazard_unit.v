// Hazard Unit: detects load-use and control hazards, generates stall/flush signals
module hazard_unit (
    input  wire        ex_mem_read,      // instruction in EX is a load
    input  wire [4:0]  ex_rd,            // destination of instruction in EX
    input  wire [4:0]  id_rs1,           // rs1 of instruction in ID
    input  wire [4:0]  id_rs2,           // rs2 of instruction in ID
    input  wire        branch_taken,     // branch resolved in EX is taken
    input  wire        jump,             // jump instruction in EX
    output wire        pc_stall,         // stall the PC
    output wire        if_id_stall,      // stall IF/ID register
    output wire        if_id_flush,      // flush IF/ID register
    output wire        id_ex_flush       // flush ID/EX register
);

    // Load-use hazard: EX instruction is a load that writes to rs1 or rs2 of ID instruction
    wire load_use;
    assign load_use = ex_mem_read &&
                      (ex_rd != 5'b0) &&
                      ((ex_rd == id_rs1) || (ex_rd == id_rs2));

    // Control hazard: branch taken or unconditional jump
    wire redirect;
    assign redirect = branch_taken || jump;

    // Stall PC and IF/ID on load-use (priority over redirect)
    assign pc_stall    = load_use;
    assign if_id_stall = load_use;

    // Flush IF/ID on redirect (unless load-use has priority)
    assign if_id_flush = redirect && !load_use;

    // Flush ID/EX on load-use (insert bubble) OR on redirect
    assign id_ex_flush = load_use || redirect;

endmodule
