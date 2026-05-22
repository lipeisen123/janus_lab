// Main Control Unit: decodes opcode, produces datapath control signals
module ctrl (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        alu_src,       // 0=rs2_data, 1=immediate
    output reg  [1:0] alu_op,        // alu operation class
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,    // 0=ALU result, 1=memory data
    output reg        branch,
    output reg        jump
);

    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_I_LOAD = 7'b0000011;
    localparam OP_S      = 7'b0100011;
    localparam OP_B      = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;

    always @(*) begin
        // Safe default (all zero = NOP)
        {reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump} = 9'b0;

        case (opcode)
            OP_R_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;    // R/I-type ALU decode
            end

            OP_I_ALU: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;    // R/I-type ALU decode
            end

            OP_I_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b00;   // ADD (address calculation)
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
            end

            OP_S: begin
                reg_write  = 1'b0;
                alu_src    = 1'b1;
                alu_op     = 2'b00;   // ADD (address calculation)
                mem_write  = 1'b1;
            end

            OP_B: begin
                reg_write = 1'b0;
                alu_src   = 1'b0;
                alu_op    = 2'b01;    // SUB (for comparison)
                branch    = 1'b1;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;    // PASS through immediate
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;    // ADD (pc + imm)
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
            end

            OP_JALR: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;    // ADD (rs1 + imm)
                jump      = 1'b1;
            end

            default: begin
                // Illegal opcode → NOP
            end
        endcase
    end

endmodule
