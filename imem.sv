module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    // 4KB = 1024 words. 内部字寻址: addr[11:2]
    logic [31:0] rom [0:1023];
    initial $readmemh("imem.hex", rom);
    
    // 组合逻辑读取，无额外延迟
    always_comb instr = rom[addr[11:2]];
endmodule
