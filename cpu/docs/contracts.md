# CPU Verification Contracts — Milestone 1

> 12 natural-language contracts covering module-level, pipeline/temporal, and ISA-level properties.
> Each contract states **what** the property is, **under what assumptions**, and **what behavior it forbids**.

---

## Module-Level Contracts

### C1 — Register x0 Hardwired to Zero (regfile)

**Module:** `regfile.v`

**Contract:**
Register x0 is hardwired to zero at all times.
- Any read from `rs1 == 0` or `rs2 == 0` returns `32'h0000_0000`, regardless of what was previously written.
- Any write to `rd == 0` with `reg_write == 1` is silently discarded and does not modify internal state.

**Assumption:** The register file clock is running.

**Forbids:** A non-zero value appearing on `rs1_data` or `rs2_data` when the read address is zero; a write to x0 changing the value read from x0 on a subsequent cycle.

---

### C2 — ALU Operation Correctness (alu)

**Module:** `alu.v`

**Contract:**
For every valid `alu_ctrl` code, the ALU computes the correct 32-bit result:
- `ADD` (0): `result = a + b` (unsigned, wrap on overflow)
- `SUB` (1): `result = a - b`
- `AND` (2): `result = a & b`
- `OR` (3): `result = a | b`
- `XOR` (4): `result = a ^ b`
- `SLL` (5): `result = a << b[4:0]`
- `SRL` (6): `result = a >> b[4:0]` (logical)
- `SRA` (7): `result = $signed(a) >>> b[4:0]` (arithmetic)
- `SLT` (8): `result = ($signed(a) < $signed(b)) ? 1 : 0`
- `SLTU` (9): `result = (a < b) ? 1 : 0`
- `PASS_B` (10): `result = b`
- The `zero` output is 1 iff `result == 0`.

**Assumption:** `alu_ctrl` is one of the 11 defined codes.

**Forbids:** Any mismatch between the specified operation and the computed result.

---

### C3 — Branch Condition Evaluation (branch_unit)

**Module:** `branch_unit.v`

**Contract:**
When `branch == 1`, the `taken` output is 1 iff the condition corresponding to `funct3` holds between `rs1_data` and `rs2_data`:
- `BEQ` (000): rs1 == rs2
- `BNE` (001): rs1 != rs2
- `BLT` (100): $signed(rs1) < $signed(rs2)
- `BGE` (101): $signed(rs1) >= $signed(rs2)
- `BLTU` (110): rs1 < rs2 (unsigned)
- `BGEU` (111): rs1 >= rs2 (unsigned)

When `branch == 0`, `taken` is always 0 regardless of `funct3` or operand values.

**Assumption:** `funct3` is a valid branch condition code when `branch == 1`.

**Forbids:** A branch being incorrectly taken or not-taken; non-branch instructions asserting `taken`.

---

### C4 — Immediate Generation Correctness (immgen)

**Module:** `immgen.v`

**Contract:**
Given a 32-bit instruction word, the immediate generator extracts and sign-extends the immediate field according to the format selected by `opcode[6:0]`:
- **I-type** (Load / I-ALU / JALR): `imm = {{20{instr[31]}}, instr[31:20]}`
- **S-type** (Store): `imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}`
- **B-type** (Branch): `imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}`
- **U-type** (LUI / AUIPC): `imm = {instr[31:12], 12'b0}`
- **J-type** (JAL): `imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}`

**Assumption:** `opcode` matches one of the 9 RV32I opcodes.

**Forbids:** Incorrect bit assembly for any format; missing sign extension; non-zero LSB for B-type and J-type.

---

### C5 — Control Signal Generation (ctrl)

**Module:** `ctrl.v`

**Contract:**
For every valid RV32I opcode, the main control unit produces the correct datapath control signals as specified in the control signal map (see `docs/spec.md`). Illegal or unknown opcodes produce all-zero control signals (safe NOP).

Specifically:
- `reg_write` is 1 for R/I-ALU/Load/LUI/AUIPC/JAL/JALR; 0 for Store/Branch.
- `mem_read` is 1 only for Load.
- `mem_write` is 1 only for Store.
- `branch` is 1 only for B-type.
- `jump` is 1 only for JAL and JALR.
- `alu_op` selects the correct ALU operation class: 00 for ld/st/AUIPC/JALR, 01 for branch, 10 for R/I-ALU, 11 for LUI.

**Assumption:** `opcode` is a 7-bit field from a decoded instruction word.

**Forbids:** Load asserting `mem_write`; Store asserting `reg_write`; Branch asserting `jump`; unknown opcode asserting any control signal.

---

## Pipeline / Temporal Contracts

### C6 — Load-Use Hazard Stall (hazard_unit + pipeline)

**Module:** `hazard_unit.v`, `cpu_pipelined.v`

**Contract:**
When the instruction in the EX stage is a load (`ex_mem_read == 1`), its destination register is not x0 (`ex_rd != 0`), and the instruction in the ID stage uses that register as a source (`ex_rd == id_rs1 || ex_rd == id_rs2`), then:
1. **PC stalls** (`pc_stall == 1`) — no new instruction fetched.
2. **IF/ID stalls** (`if_id_stall == 1`) — the dependent instruction is held in ID.
3. **ID/EX is flushed** (`id_ex_flush == 1`) — a NOP bubble enters EX.

The stall lasts exactly **one cycle**, after which forwarding from MEM/WB resolves the hazard.

**Assumption:** The pipeline is running and not in reset.

**Forbids:** The dependent instruction entering EX without a bubble; PC advancing during the stall; the stall persisting beyond one cycle.

---

### C7 — Taken Branch / Jump Flush (hazard_unit + pipeline)

**Module:** `hazard_unit.v`, `cpu_pipelined.v`

**Contract:**
When a branch is resolved as taken (`branch_taken == 1`) or an unconditional jump is in EX (`jump == 1`):
1. **IF/ID is flushed** (`if_id_flush == 1`) — the wrongly-fetched instruction is discarded.
2. **ID/EX is flushed** (`id_ex_flush == 1`) — the instruction following the branch/jump is discarded.
3. **PC is redirected** to the target address in the same cycle.

If both load-use and branch-taken occur simultaneously, **stall takes priority over flush** (`if_id_flush == 0` when `load_use == 1`).

**Assumption:** `branch_taken` and `jump` are resolved in the EX stage.

**Forbids:** Wrong-path instructions committing to architectural state (registers or memory); PC not redirected; flush signals not asserted.

---

### C8 — Forwarding Priority and Freshness (forward_unit)

**Module:** `forward_unit.v`

**Contract:**
When a RAW hazard exists between an instruction in EX and earlier instructions in MEM or WB:
1. **EX/MEM forwarding (2'b10) takes priority** over MEM/WB forwarding (2'b01) when both match the same source register.
2. Forwarding is suppressed when the destination register is x0 (`rd != 5'b0` guard).
3. When no hazard exists, `forward_a` and `forward_b` are `2'b00` (use register file data).

**Assumption:** `mem_reg_write`, `wb_reg_write`, and the corresponding `rd` addresses are valid from the pipeline registers.

**Forbids:** Forwarding stale data from MEM/WB when newer data is available from EX/MEM; forwarding from x0; failing to forward when a RAW hazard exists.

---

### C9 — PC Word Alignment Invariant (pc + cpu)

**Modules:** `pc.v`, `cpu.v`, `cpu_pipelined.v`

**Contract:**
The program counter is always word-aligned: `pc[1:0] == 2'b00` in every cycle after reset.
- Reset initializes PC to `0x0000_0000` (aligned).
- All next-PC sources produce aligned addresses:
  - `pc + 4` is word-aligned (since pc is aligned).
  - Branch and JAL targets are `pc + imm` where `imm[0] == 0` (from B/J-type immediate encoding).
  - JALR target is `(rs1 + imm) & ~1` where LSB is explicitly cleared.

**Assumption:** The reset sequence completes normally.

**Forbids:** Any cycle where `pc[1:0] != 2'b00` after reset.

---

### C10 — No Writeback from Flushed Instructions

**Modules:** `pipeline_regs.v`, `cpu_pipelined.v`

**Contract:**
When a pipeline register stage is flushed, the control signals in that stage are zeroed (NOP). A NOP in any stage:
- Has `reg_write == 0` → does not modify the register file.
- Has `mem_write == 0` → does not modify data memory.
- Has `branch == 0` and `jump == 0` → does not redirect PC.

The NOP encoding (`32'h0000_0013` = ADDI x0, x0, 0) produces no architectural side effect even if it reaches WB.

**Assumption:** Flush signals are generated correctly by the hazard unit.

**Forbids:** A flushed instruction writing a non-zero value to a register; a flushed store writing to memory; a flushed branch redirecting the PC.

---

## ISA-Level Contracts

### C11 — ADD Instruction Semantic Contract

**Scope:** R-type `ADD` instruction (opcode=`0110011`, funct3=`000`, funct7=`0000000`)

**Contract:**
When the CPU executes `ADD rd, rs1, rs2`:
- **Architectural effect:** `reg[rd] = reg[rs1] + reg[rs2]` (32-bit unsigned wrap).
- **No memory access:** `mem_read == 0`, `mem_write == 0`.
- **No PC discontinuity:** PC advances to `pc + 4` (no branch, no jump).
- **rd == x0 case:** If `rd == 0`, the register file state is unchanged (x0 remains 0).

**Assumption:** The instruction is correctly fetched and decoded as ADD.

**Forbids:** ADD modifying memory; ADD changing PC non-sequentially; ADD producing a result different from `rs1 + rs2`.

---

### C12 — LW Instruction Semantic Contract

**Scope:** I-type `LW` instruction (opcode=`0000011`, funct3=`010`)

**Contract:**
When the CPU executes `LW rd, imm(rs1)`:
- **Address calculation:** `addr = reg[rs1] + sign_extend(imm)` — must be word-aligned (`addr[1:0] == 0`).
- **Memory read:** Four bytes at `addr` are read from DMEM, assembled in little-endian order.
- **Architectural effect:** `reg[rd] = mem[addr]` (32-bit word).
- **No memory write:** `mem_write == 0`.
- **WB mux:** `mem_to_reg == 1` → writeback data comes from memory, not ALU.

**Assumption:** The effective address is word-aligned; DMEM contains valid data.

**Forbids:** LW writing to memory; LW writing ALU result to rd instead of memory data; LW reading from a misaligned address without trap (not supported in baseline).

---

### C13 — JAL/JALR Link and Jump Contract

**Scope:** J-type `JAL` (opcode=`1101111`) and I-type `JALR` (opcode=`1100111`)

**Contract:**
**JAL:**
- `reg[rd] = pc + 4` (return address saved).
- `pc_next = pc + sext(imm)` (PC-relative jump, ±1 MB range).
- If `rd == x0`, return address is discarded (unconditional jump without link).

**JALR:**
- `reg[rd] = pc + 4` (return address saved).
- `pc_next = (reg[rs1] + sext(imm)) & ~1` (indirect jump, LSB cleared).
- If `rd == x0`, return address is discarded (used for `ret` as `jalr x0, 0(ra)`).

**Both:**
- No memory access.
- `jump == 1`, `reg_write == 1` (when rd != x0).

**Assumption:** The target address is word-aligned after computation.

**Forbids:** JAL/JALR writing to memory; JALR not clearing LSB of the target; link address being anything other than `pc + 4`.

---

## Contract Summary

| # | Level | Module / Scope | Key Property |
|---|-------|---------------|--------------|
| C1 | Module | regfile | x0 hardwired to zero |
| C2 | Module | alu | All 11 operations match spec |
| C3 | Module | branch_unit | 6 branch conditions, gated by `branch` |
| C4 | Module | immgen | 5 immediate formats, correct bit assembly |
| C5 | Module | ctrl | 9 opcodes → correct control signals |
| C6 | Temporal | hazard_unit | Load-use → stall PC + IF/ID, flush ID/EX |
| C7 | Temporal | hazard_unit | Taken branch/jump → flush, redirect PC |
| C8 | Temporal | forward_unit | EX/MEM > MEM/WB priority, x0 guard |
| C9 | Temporal | pc + top | PC word-aligned invariant across all cycles |
| C10 | Temporal | pipeline_regs | Flushed instructions produce no side effects |
| C11 | ISA | ADD | rd = rs1 + rs2, no mem, PC+4 |
| C12 | ISA | LW | rd = mem[rs1+imm], mem_to_reg=1 |
| C13 | ISA | JAL/JALR | rd = pc+4, correct target computation |

**Count:** 5 module + 5 temporal/pipeline + 3 ISA = **13 contracts**
