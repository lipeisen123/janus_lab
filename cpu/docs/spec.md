# Janus CPU Specification

## Architecture
- **ISA**: RV32I base integer (47 instructions)
- **Design**: Harvard (separate IMEM / DMEM)
- **Phases**: Single-cycle datapath → 5-stage pipeline → extensions

## Module Inventory

| Module | Role |
|--------|------|
| `pc` | Program counter, 32-bit, reset to 0x0000_0000 |
| `imem` | Instruction ROM, 256×32-bit, combinational read |
| `regfile` | 32×32-bit registers, async read, sync write, x0=0, RDW forwarding |
| `immgen` | Immediate extraction: I/S/B/U/J formats |
| `ctrl` | Opcode → control signals (reg_write, alu_src, alu_op, mem_read, mem_write, mem_to_reg, branch, jump) |
| `alu` | 11 ops: ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/PASS |
| `aluctrl` | Two-level decode: (alu_op, funct3, funct7[5]) → 4-bit ALU code |
| `dmem` | 4KB byte-addressable RAM, sub-word loads/stores |
| `branch_unit` | 6 conditions: BEQ/BNE/BLT/BGE/BLTU/BGEU, gated by branch signal |
| `if_id_reg` | Pipeline register: PC + instruction |
| `id_ex_reg` | Pipeline register: control, data, addresses; supports flush |
| `ex_mem_reg` | Pipeline register: ALU result, store data, control |
| `mem_wb_reg` | Pipeline register: ALU result, memory data, control |
| `hazard_unit` | Detects load-use (stall) and control hazards (flush) |
| `forward_unit` | RAW forwarding: EX/MEM and MEM/WB → ALU inputs |

## Control Signal Map

| Instruction | reg_write | alu_src | alu_op | mem_read | mem_write | mem_to_reg | branch | jump |
|-------------|-----------|---------|--------|----------|-----------|------------|--------|------|
| R-type | 1 | 0 | 10 | 0 | 0 | 0 | 0 | 0 |
| I-arithmetic | 1 | 1 | 10 | 0 | 0 | 0 | 0 | 0 |
| Load | 1 | 1 | 00 | 1 | 0 | 1 | 0 | 0 |
| Store | 0 | 1 | 00 | 0 | 1 | 0 | 0 | 0 |
| Branch | 0 | 0 | 01 | 0 | 0 | 0 | 1 | 0 |
| LUI | 1 | 1 | 11 | 0 | 0 | 0 | 0 | 0 |
| AUIPC | 1 | 1 | 00 | 0 | 0 | 0 | 0 | 0 |
| JAL | 1 | 0 | — | 0 | 0 | 0 | 0 | 1 |
| JALR | 1 | 1 | 00 | 0 | 0 | 0 | 0 | 1 |

## Opcode Map

| Opcode[6:0] | Class |
|-------------|-------|
| 0110011 | R-type |
| 0010011 | I-type ALU |
| 0000011 | Load |
| 0100011 | Store |
| 1100011 | Branch |
| 0110111 | LUI |
| 0010111 | AUIPC |
| 1101111 | JAL |
| 1100111 | JALR |

## Pipeline Hazard Rules
- **Load-use**: Stall PC + IF/ID, flush ID/EX for 1 cycle
- **Branch taken / Jump**: Flush IF/ID + ID/EX, redirect PC
- **Stall > Flush**: If both asserted, stall wins
- **Forwarding**: EX/MEM priority over MEM/WB; rd != x0 guard

## Exclusions
- No FENCE, ECALL, EBREAK in baseline (Phase 3 stretch)
- No unaligned memory access
- Little-endian byte ordering
