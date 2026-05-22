// Branch Unit: evaluates branch conditions for all 6 RISC-V conditional branches
module branch_unit (
    input  wire        branch,        // from ctrl: is this a branch instruction?
    input  wire [2:0]  funct3,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    output wire        taken
);

    reg condition;

    always @(*) begin
        case (funct3)
            3'b000: condition = (rs1_data == rs2_data);                          // BEQ
            3'b001: condition = (rs1_data != rs2_data);                          // BNE
            3'b100: condition = ($signed(rs1_data) < $signed(rs2_data));         // BLT
            3'b101: condition = ($signed(rs1_data) >= $signed(rs2_data));        // BGE
            3'b110: condition = (rs1_data < rs2_data);                           // BLTU
            3'b111: condition = (rs1_data >= rs2_data);                          // BGEU
            default: condition = 1'b0;
        endcase
    end

    assign taken = branch & condition;

endmodule
