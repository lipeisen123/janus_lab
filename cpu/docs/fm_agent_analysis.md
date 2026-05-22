# FM-Agent Adaptation Analysis — Milestone 4

## What Maps from Software FM-Agent to CPU Hardware

| FM-Agent Concept | Software View | Hardware Migration (This Lab) |
|------------------|---------------|-------------------------------|
| **Function** | Code block with signature | Verilog module or pipeline stage |
| **Caller expectation** | Function usage context | Downstream module usage (e.g., `cpu.v` uses `pc_stall`) |
| **Domain knowledge** | Language spec, coding style | ISA spec (RV32I), microarchitecture spec (`docs/spec.md`) |
| **Pre-condition** | Input constraint before call | Assumption on input signals / pipeline state |
| **Post-condition** | Output guarantee after call | Assertion on output signals / architectural effect |
| **Bug validator** | System-entry test case | Assembly program + Verilator/Icarus run |
| **Natural-language Hoare** | LLM-reasoned pre/post | Agent-proposed contracts from spec + RTL |

## What Does Not Map Easily

1. **Sequential vs. concurrent**: FM-Agent targets sequential software functions. CPU hardware is inherently concurrent — all pipeline stages run simultaneously. A "post-condition" in hardware is often a temporal commitment (e.g., "2 cycles after a load-use, the value is forwarded"), not a termination guarantee.

2. **Side effects**: In software, a function can directly read/write global state. In hardware, every clock edge is a global synchronization point. The "side effects" (register writes, memory writes) are the architecture itself.

3. **Ambiguity tolerance**: FM-Agent uses natural-language specs, which are necessarily ambiguous. For hardware, ambiguous specs leave room for mismatches between what the RTL does and what the designer intended. This project observed that module-level contracts were less ambiguous than pipeline-level ones.

## Agent-Assisted vs. Human-Driven

| Activity | Agent Role | Human Role |
|----------|-----------|------------|
| Contract mining | Proposed initial drafts from `spec.md` + RTL | Reviewed, corrected signal names, tightened guard conditions |
| Contract translation (C1, C2) | Suggested assertion templates | Wrote exact Verilog with correct module hierarchy and port names |
| Contract translation (C6) | Identified load-use as high-value temporal contract | Encoded the precise combinational conditions from RTL |
| Bug validation | Suggested branch condition swap as test bug class | Designed the minimal detection program with discriminating test vectors |
| Bug report fields | — | Human-structured: contract violated, trigger, evidence, root cause, fix |

## Where the Agent Was Wrong or Ambiguous

1. **Signal naming**: The agent initially used abstract names (`mem_read_in_ex`, `destination_register`). These had to be mapped to actual RTL signal names (`ex_mem_read`, `ex_rd`).

2. **Temporal quantification**: The agent proposed "G(load_use → X stall)" which is an SVA-style temporal formula. Translating this to a combinational check on the hazard unit required understanding that load-use is inherently a single-cycle phenomenon — the combinational output of `hazard_unit` already encodes the correct behavior for the current state.

3. **Coverage vs. correctness**: The agent conflated "the ALU should compute correctly" (a correctness property) with "all ALU operations should be exercised" (a coverage property). The former is an assertion; the latter is a cover point. Human judgment was needed to separate these.

4. **x0 semantics**: The agent initially missed the subtlety of read-during-write forwarding on x0 — it proposed checking only that reads return 0, not that writes are silently discarded even under RDW.

## Lessons Learned

1. **Keep contracts module-scoped**: Module-level contracts (C1-C5) were the easiest to write and translate because they are combinational and self-contained. Pipeline-level contracts (C6-C8) required cross-module signal knowledge.

2. **Test vectors must discriminate**: The bug detection test for BLT/BLTU demonstrates that test vectors where signed and unsigned comparisons agree (e.g., 5 < 10) will NOT catch the bug. Choosing discriminating vectors (negative numbers, large unsigned values) requires domain knowledge.

3. **Start with simulation, graduate to formal**: All contracts in this lab were validated via simulation (Icarus Verilog). The stretch goal of connecting to SymbiYosys for formal proof would require additional work on the SMT-LIB encoding of these properties.

## Conclusion

The FM-Agent approach of mining natural-language contracts and translating them to executable checks is viable for hardware verification at the module level. The main friction points are signal-name mapping (solvable with better RTL parsing) and temporal reasoning (solvable with SVA templates). For a 13-module CPU design, the manual overhead of writing 12 contracts and 3 executable harnesses was approximately 4-6 hours, comparable to the time spent writing directed tests.
