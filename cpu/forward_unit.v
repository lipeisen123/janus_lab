// Forwarding Unit: detects RAW hazards resolvable by forwarding
module forward_unit (
    input  wire        mem_reg_write,   // EX/MEM register has reg_write asserted
    input  wire [4:0]  mem_rd,          // EX/MEM destination register
    input  wire        wb_reg_write,    // MEM/WB register has reg_write asserted
    input  wire [4:0]  wb_rd,           // MEM/WB destination register
    input  wire [4:0]  ex_rs1,          // EX stage rs1 address
    input  wire [4:0]  ex_rs2,          // EX stage rs2 address
    output reg  [1:0]  forward_a,       // mux select for ALU input A
    output reg  [1:0]  forward_b        // mux select for ALU input B
);

    // 2'b00: no forwarding (use regfile data)
    // 2'b10: forward from EX/MEM (highest priority)
    // 2'b01: forward from MEM/WB

    always @(*) begin
        // Forward A (rs1_data for ALU)
        if (mem_reg_write && mem_rd != 5'b0 && mem_rd == ex_rs1)
            forward_a = 2'b10;    // EX/MEM forwarding (newest data)
        else if (wb_reg_write && wb_rd != 5'b0 && wb_rd == ex_rs1)
            forward_a = 2'b01;    // MEM/WB forwarding
        else
            forward_a = 2'b00;    // no forwarding, use register file

        // Forward B (rs2_data for ALU)
        if (mem_reg_write && mem_rd != 5'b0 && mem_rd == ex_rs2)
            forward_b = 2'b10;    // EX/MEM forwarding (newest data)
        else if (wb_reg_write && wb_rd != 5'b0 && wb_rd == ex_rs2)
            forward_b = 2'b01;    // MEM/WB forwarding
        else
            forward_b = 2'b00;    // no forwarding, use register file
    end

endmodule
