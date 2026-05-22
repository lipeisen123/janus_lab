# Hoare-Style Induction Proof: Register x0 Is Always Zero

## 1. What We Are Proving

**Invariant P**: The internal register `regs[0]` is always `32'h0000_0000` in every reachable state of the CPU.

Why this matters: x0 is the architectural zero register in RISC-V. If it ever becomes non-zero,
every instruction that uses x0 (which is almost all programs, all the time) could produce wrong results.
This is a **safety property** — "nothing bad ever happens to x0."

## 2. State Space and Transition Relation

### State
The relevant state for this proof is the register file's internal array:
```
S = (regs[0], regs[1], ..., regs[31])
```
All 32 registers are 32-bit values. The full CPU state includes PC, memory, and pipeline
registers, but they do not affect whether x0 stays zero — the only way to change a register
is through the register file's write port.

### Initial State (Init)
From `regfile.v` lines 17–19, after reset or simulation start:
```
∀i ∈ [0, 31]: regs[i] = 32'h0000_0000
```
Therefore `Init → regs[0] = 0`. ✓

### Transition Relation (Next)
From `regfile.v` lines 23–25, on every positive clock edge:
```
if (reg_write && rd != 5'b0)
    regs[rd] <= rd_data;
```
All other `regs[i]` keep their previous value. This is the ONLY mechanism that modifies
the register array. Combinational reads do not change state.

## 3. Inductive Proof

### Theorem
```
∀ reachable state s: regs[0] = 0
```

### Base Case
```
Init(s₀) → regs[0] = 0
```
Proof: At time zero (or after reset), the `initial` block in `regfile.v` sets every register
to `32'h0000_0000`. Therefore `regs[0] = 0`. ✓

### Inductive Step
```
Inductive hypothesis: regs[0] = 0 in state sₖ
To prove:            regs[0] = 0 in state sₖ₊₁
```

The transition from `sₖ` to `sₖ₊₁` occurs at `posedge clk`. There are exactly two cases:

**Case A: No write, or write target is not x0.**
The write condition `reg_write && rd != 5'b0` is either false (no write), or true with
`rd ∈ {1, 2, ..., 31}` (writing to a non-zero register). In both sub-cases, `regs[0]`
is NOT the target of the write. Therefore `regs[0]` retains its value from `sₖ`.
By the inductive hypothesis, `regs[0] = 0` in `sₖ`, so `regs[0] = 0` in `sₖ₊₁`. ✓

**Case B: Write, and write target IS x0.**
This means `reg_write = 1` and `rd = 5'b0`. However, the write condition in `regfile.v`
line 24 explicitly requires `rd != 5'b0`. Since `rd = 5'b0`, the guard `rd != 5'b0`
evaluates to FALSE, and the write is **not executed**. `regs[0]` is unchanged.
By the inductive hypothesis, `regs[0] = 0` in `sₖ`, so `regs[0] = 0` in `sₖ₊₁`. ✓

Both cases lead to `regs[0] = 0` in `sₖ₊₁`. The inductive step holds. ✓

### Conclusion
By mathematical induction, `regs[0] = 0` in all reachable states. ∎

## 4. Hoare Triple Formulation

The invariant can be expressed as a Hoare triple over one clock cycle:

```
{regs[0] == 0}
    one clock cycle (posedge clk)
{regs[0] == 0}
```

Read as: "If x0 is zero before a clock edge, it is zero after the clock edge."

This triple is **valid** because the register file's synchronous write logic contains
the guard `rd != 5'b0`, which makes it structurally impossible to write to x0.

### Subcontracts (Compositional Decomposition)

Following FM-Agent's compositional reasoning approach, the x0 invariant decomposes into
three smaller Hoare triples:

**C_write_x0 (Write Silence)**
```
{reg_write == 1 ∧ rd == 5'b0}
    posedge clk
{regs[0] == \old(regs[0])}
```
"The write is silently discarded."

**C_idle_x0 (No Write)**
```
{rd != 5'b0 ∨ reg_write == 0}
    posedge clk
{regs[0] == \old(regs[0])}
```
"If no one tries to write x0, it stays unchanged."

**C_read_x0 (Read Zero — Combinational)**
```
{rs1 == 5'b0}
    combinational read (no clock)
{rs1_data == 32'h0000_0000}
```
"Any read of x0 returns zero immediately, no clock needed."

The first two are **temporal** (they span a clock edge). The third is **combinational**
(it holds continuously, not just at edges).

## 5. Why This Induction Is Relatively Easy

This invariant is "inductive on its own" — meaning it needs no auxiliary (helper) invariants
to make the step go through. This is rare in hardware verification. Most CPU invariants
require strengthening:

| Invariant | Needs auxiliary invariants? |
|-----------|:---:|
| x0 always zero | No — structural guard is sufficient |
| PC always aligned | Yes — needs invariants about immediate LSB and JALR masking |
| No writeback from flushed instructions | Yes — needs invariants about flush signal generation |

The reason x0 needs no helper: the guard `rd != 5'b0` is a **syntactic** fact about the
RTL code, not a **semantic** fact about the state. It holds regardless of any other signal's
value.

## 6. Proof Validation Strategy

A full formal proof would use SymbiYosys in `--mode prove` to check induction automatically.
Since the lab uses Icarus Verilog for simulation, we validate the proof through
**exhaustive bounded checking**:

1. **Combinational check**: Enumerate all possible `rs1`/`rs2` values (0–31) and verify
   reads of x0 always return 0. (Trivially passes — checked in `formal_regfile_x0.v`.)

2. **Write-enumeration check**: For every possible `rd` value (0–31), perform a write
   with `reg_write = 1`, then check `regs[0]` in the next cycle. Since `rd` is only 5 bits,
   this is **exhaustive** — 32 writes cover every possible transition.

3. **RDW check**: Write to x0 with `reg_write = 1, rd = 0` and simultaneously read x0
   (`rs1 = 0`). The combinational read must return 0, not the value being written.

The exhaustive write enumeration (step 2) effectively proves the inductive step, because
the transition relation's only degree of freedom for changing `regs[0]` is the 5-bit
`rd` signal.

## 7. Rerunnable Evidence

The verification harness `checks/induction_x0.v` implements the three checks above
and can be run with:
```
make check-x0-induction
```

A successful run produces output like:
```
[Base]  After reset, regs[0] = 0          : PASS
[Step]  All 32 rd values: regs[0] stays 0 : PASS
[RDW]   Write x0, read same cycle → 0     : PASS
[Comb]  All rs1: x0 read returns 0        : PASS
[Comb]  All rs2: x0 read returns 0        : PASS
=== x0 Induction Proof Validated ===
```

A failure would produce a concrete counterexample trace showing:
- Which `rd` value caused the violation
- What the register file state was before and after
- The exact clock cycle of the failure
