// Immediate Generator: extracts and sign-extends immediates from instruction word
module immgen (
    input  wire [6:0]  opcode,       // opcode field instr[6:0]
    input  wire [31:0] instr,        // full instruction word
    output reg  [31:0] imm           // 32-bit sign-extended immediate
);

    // Opcode constants
    localparam OP_I_LOAD  = 7'b0000011;   // Load instructions (I-type)
    localparam OP_I_ALU   = 7'b0010011;   // I-type arithmetic
    localparam OP_I_JALR  = 7'b1100111;   // JALR (I-type)
    localparam OP_S       = 7'b0100011;   // Store (S-type)
    localparam OP_B       = 7'b1100011;   // Branch (B-type)
    localparam OP_LUI     = 7'b0110111;   // LUI (U-type)
    localparam OP_AUIPC   = 7'b0010111;   // AUIPC (U-type)
    localparam OP_JAL     = 7'b1101111;   // JAL (J-type)

    always @(*) begin
        case (opcode)
            OP_I_LOAD, OP_I_ALU, OP_I_JALR:
                // I-type: imm[11:0] at instr[31:20]
                imm = {{20{instr[31]}}, instr[31:20]};

            OP_S:
                // S-type: imm[11:5] at instr[31:25], imm[4:0] at instr[11:7]
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            OP_B:
                // B-type: scrambled bits, imm[0] always 0
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            OP_LUI, OP_AUIPC:
                // U-type: imm[31:12] at instr[31:12], lower 12 bits zero
                imm = {instr[31:12], 12'b0};

            OP_JAL:
                // J-type: scrambled bits, imm[0] always 0
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};

            default:
                imm = 32'h0000_0000;
        endcase
    end

endmodule
