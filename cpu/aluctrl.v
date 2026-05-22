// ALU Control Decoder: two-level decode from alu_op + funct3/funct7
module aluctrl (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,      // funct7[5] (distinguishes SRL/SRA, ADD/SUB)
    output reg  [3:0] alu_ctrl
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

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;    // load / store address calc
            2'b01: alu_ctrl = ALU_SUB;     // branch comparison
            2'b11: alu_ctrl = ALU_PASS;    // LUI
            2'b10: begin                    // R-type or I-type arithmetic
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            default: alu_ctrl = ALU_ADD;
        endcase
    end

endmodule
