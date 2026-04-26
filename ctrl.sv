module ctrl (
    input  logic [6:0] opcode,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       alu_src,
    output logic       mem_to_reg,
    output logic       branch,
    output logic       jump,
    output logic [1:0] alu_op
);
    always_comb begin
        reg_write   = 1'b0; mem_read  = 1'b0; mem_write = 1'b0;
        alu_src     = 1'b0; mem_to_reg = 1'b0;
        branch      = 1'b0; jump      = 1'b0; alu_op    = 2'b00;
        case (opcode)
            7'b0110011: begin reg_write=1; alu_op=2'b10; end                     // R-type
            7'b0000011: begin reg_write=1; mem_read=1; alu_src=1; mem_to_reg=1; alu_op=2'b00; end // LOAD
            7'b0100011: begin mem_write=1; alu_src=1; alu_op=2'b00; end         // STORE
            7'b1100011: begin branch=1; alu_op=2'b01; end                       // BRANCH
            7'b0010011: begin reg_write=1; alu_src=1; alu_op=2'b10; end         // I-type ALU
            7'b1101111: begin reg_write=1; jump=1; alu_src=1; mem_to_reg=1; alu_op=2'b00; end // JAL
            7'b1100111: begin reg_write=1; jump=1; alu_src=1; mem_to_reg=1; alu_op=2'b00; end // JALR
            7'b0110111: begin reg_write=1; alu_src=1; mem_to_reg=0; alu_op=2'b00; end // LUI
            7'b0010111: begin reg_write=1; alu_src=1; mem_to_reg=0; alu_op=2'b00; end // AUIPC
            default: begin end
        endcase
    end
endmodule
