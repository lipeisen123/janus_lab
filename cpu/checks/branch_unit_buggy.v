// BUGGY branch_unit — BLT/BLTU swapped (a realistic signed/unsigned confusion bug)
// This file is a DELIBERATE BUG INJECTION for Milestone 3 validation.
// Bug: BLT (funct3=100) uses unsigned comparison instead of signed
//      BLTU (funct3=110) uses signed comparison instead of unsigned
module branch_unit_buggy (
    input  wire        branch,
    input  wire [2:0]  funct3,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    output wire        taken
);

    reg condition;

    always @(*) begin
        case (funct3)
            3'b000: condition = (rs1_data == rs2_data);                          // BEQ ✓
            3'b001: condition = (rs1_data != rs2_data);                          // BNE ✓
            // BUG: BLT uses unsigned comparison (should be $signed)
            3'b100: condition = (rs1_data < rs2_data);                           // BLT ✗ (should be signed)
            // BUG: BLTU uses signed comparison (should be unsigned)
            3'b110: condition = ($signed(rs1_data) < $signed(rs2_data));         // BLTU ✗ (should be unsigned)
            3'b101: condition = ($signed(rs1_data) >= $signed(rs2_data));        // BGE ✓
            3'b111: condition = (rs1_data >= rs2_data);                          // BGEU ✓
            default: condition = 1'b0;
        endcase
    end

    assign taken = branch & condition;

endmodule
