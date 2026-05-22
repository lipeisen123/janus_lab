# CPU Verification Report — Lab 02

## Environment

| Item | Value |
|------|-------|
| Simulator | Icarus Verilog (iverilog) / Verilator |
| Waveform viewer | GTKWave |
| Lint tool | Verilator --lint-only (optional) |
| Synthesis check | Yosys (optional) |
| CPU variant | Single-cycle (`cpu.v`) and 5-stage pipelined (`cpu_pipelined.v`) |
| ISA | RV32I base integer (47 instructions) |
| Test date | 2026-05-17 |

## Test Plan

### Level 1: Module Tests (6 tests)
Each module tested in isolation with directed input vectors and combinational/sequential assertions.

| # | Module | Test file | What is checked |
|---|--------|-----------|-----------------|
| M1 | alu | `checks/formal_alu.v` | 11 ALU operations, zero flag, overflow wraparound, signed/unsigned |
| M2 | regfile | `checks/formal_regfile_x0.v` | x0 reads=0, x0 writes ignored, RDW forwarding, x0 RDW immunity |
| M3 | ctrl | `checks/check_ctrl.v` | 9 opcodes → correct control signals; illegal opcode → NOP |
| M4 | immgen | `checks/check_immgen.v` | I/S/B/U/J format bit assembly, sign extension, B/J LSB=0 |
| M5 | hazard_unit | `checks/formal_hazard_unit.v` | Load-use → stall+flush; branch/jump → flush; priority rules |
| M6 | dmem | `checks/check_dmem.v` | LB/LH/LW/LBU/LHU sign/zero extension, SB/SH/SW byte lanes |

### Level 2: Instruction Tests (10 tests)
Each test is an assembly program that executes a specific instruction type and self-reports PASS/FAIL via the 0xFFFF_0000 magic address.

| # | Test | Instructions covered | Key corner cases |
|---|------|---------------------|-----------------|
| I1 | test_add | ADD | Positive addition, overflow wrap (0xFFFFFFFF+1=0), rd=x0 discard |
| I2 | test_sub | SUB | Positive, zero result (5-5=0), negative result (0-1=-1) |
| I3 | test_slt_sltu | SLT, SLTU | -1<0 (signed T, unsigned F), positive values (both agree) |
| I4 | test_lui | LUI | Upper 20-bit load, lower 12 bits zero, sign extension of MSB |
| I5 | test_auipc | AUIPC | PC+0=PC, PC+offset delta, consecutive AUIPC same result |
| I6 | test_shift | SLL, SRL, SRA | Shift by 0/1/31, arithmetic vs logical right of 0x80000000 |
| I7 | test_logic | AND, OR, XOR | Alternating bit patterns, identity laws (AND self, XOR self) |
| I8 | test_lw_sw | LW, SW | Store-load round-trip, different addresses not corrupted |
| I9 | test_branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | All 6 types taken/not-taken, signed vs unsigned distinction |
| I10 | test_jal | JAL, JALR | Link address = pc+4, JALR LSB clearing, rd=x0 jump |

### Level 3: Hazard Tests (3 tests — pipelined only)
Tests that verify pipeline-specific timing behavior.

| # | Test | Hazard type | What is checked |
|---|------|-------------|-----------------|
| H1 | test_load_use | Load-use data hazard | LW→ADD (dependent): must stall 1 cycle or data is stale |
| H2 | test_forwarding | RAW data hazard | EX/MEM and MEM/WB forwarding, priority, x0 non-forwarding |
| H3 | test_branch_flush | Control hazard | Wrong-path register/memory writes must NOT commit |

### Level 4: Bug Detection (1 test)
| # | Test | Bug injected |
|---|------|-------------|
| B1 | tb_branch_bug_detect | BLT/BLTU signed/unsigned swap in branch_unit |

## Results Summary

### Module Tests

| Test | Status | Notes |
|------|--------|-------|
| M1: ALU | — | Run via `make check-alu` |
| M2: RegFile x0 | — | Run via `make check-regfile` |
| M3: Ctrl | — | Run via `make check-ctrl` |
| M4: ImmGen | — | Run via `make check-immgen` |
| M5: Hazard Unit | — | Run via `make check-hazard` |
| M6: Data Memory | — | Run via `make check-dmem` |

### Instruction Tests

| Test | Single-cycle | Pipelined | Notes |
|------|:---:|:---:|-------|
| test_add | — | — | |
| test_sub | — | — | |
| test_slt_sltu | — | — | |
| test_lui | — | — | |
| test_auipc | — | — | |
| test_shift | — | — | |
| test_logic | — | — | |
| test_lw_sw | — | — | |
| test_branch | — | — | |
| test_jal | — | — | |

### Hazard Tests (pipelined)

| Test | Status | Notes |
|------|:---:|-------|
| test_load_use | — | |
| test_forwarding | — | |
| test_branch_flush | — | |

### Bug Detection

| Test | Golden | Buggy | Notes |
|------|:---:|:---:|-------|
| tb_branch_bug_detect | — | — | |

## Bugs Found and Fixed

### BU-001: BLT/BLTU signed/unsigned swap (injected)
- **Symptom**: BLT -1 < 0 not taken (expected taken)
- **Root cause**: BLT used unsigned comparison; BLTU used signed comparison
- **Fix**: Swap comparison operators for funct3 3'b100 and 3'b110
- **Evidence**: `make check-bug` — golden passes, buggy fails with 2 test vectors

*(Add additional bugs as found during regression)*

## Waveform Debug Evidence

*(Attach a screenshot or signal list from GTKWave showing the first wrong cycle
for one debug case. Suggested signals: clk, rst_n, pc, id_instr, ex_rd,
wb_reg_write, wb_rd_data.)*

## Known Limitations

1. FENCE, ECALL, EBREAK not implemented (Phase 3 stretch goals)
2. No unaligned memory access support
3. No trap/interrupt handling (CSRs not implemented)
4. Branch prediction: predict-not-taken only (static)
5. No data cache or instruction cache
6. Coverage metrics not yet collected (Verilator coverage flags not enabled)

## How to Run

```bash
# Full regression (all tests)
make regress

# Individual categories
make check-all           # All module tests
make check-alu           # ALU only
make lint                # Verilator lint

# Specific CPU simulation
make CPU=single sim      # Single-cycle
make CPU=pipelined sim   # Pipelined

# Bug detection
make check-bug
```
