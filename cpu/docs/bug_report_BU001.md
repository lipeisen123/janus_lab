# Bug Report — Milestone 3
#
# Bug ID: BU-001
# Title: BLT and BLTU comparisons swapped in branch_unit
# Status: Confirmed with rerunnable evidence
# Discovered by: FM-Agent contract validation (C3)

## Contract Violated
**C3 — Branch Condition Evaluation:**
> BLT (funct3=100): `$signed(rs1_data) < $signed(rs2_data)`
> BLTU (funct3=110): `rs1_data < rs2_data` (unsigned)

## Root Cause
In `branch_unit.v`, the comparison types for BLT and BLTU are swapped:
- BLT uses **unsigned** comparison instead of **signed**
- BLTU uses **signed** comparison instead of **unsigned**

This is a signed/unsigned confusion bug — a common class of hardware error where
the developer writes `rs1 < rs2` when `$signed(rs1) < $signed(rs2)` is needed.

## Trigger
Any BLT or BLTU instruction where the signed and unsigned comparisons disagree.
Minimal example:

```assembly
# BLT test: -1 < 0 should be TAKEN
addi x1, x0, -1      # x1 = 0xFFFFFFFF
blt  x1, x0, target  # signed: -1 < 0 = TRUE → should branch
addi x2, x0, 1       # should be skipped
target:
addi x3, x0, 0       # BUG: we reach here (branch NOT taken)

# BLTU test: 0xFFFFFFFF < 0 should be NOT TAKEN
addi x1, x0, -1      # x1 = 0xFFFFFFFF
bltu x1, x0, target2  # unsigned: 0xFFFFFFFF < 0 = FALSE → should not branch
addi x2, x0, 1        # BUG: we branch over this (taken incorrectly)
target2:
```

## Evidence: Rerunnable Commands

### 1. Run golden (passes):
```
iverilog -o tb_branch_bug_detect.vvp checks/tb_branch_bug_detect.v checks/../branch_unit.v
vvp tb_branch_bug_detect.vvp
# Expected output: ALL 5 tests passed
```

### 2. Run with bug injected (fails):
```
iverilog -DINJECT_BUG -o tb_branch_bug_detect_bug.vvp checks/tb_branch_bug_detect.v checks/branch_unit_buggy.v
vvp tb_branch_bug_detect_bug.vvp
# Expected output: BUG DETECTED: 2 test(s) failed
```

## Fix
In `branch_unit.v`, swap the comparison operators for funct3 3'b100 and 3'b110:

```diff
- 3'b100: condition = (rs1_data < rs2_data);                           // BLT
+ 3'b100: condition = ($signed(rs1_data) < $signed(rs2_data));         // BLT
- 3'b110: condition = ($signed(rs1_data) < $signed(rs2_data));         // BLTU
+ 3'b110: condition = (rs1_data < rs2_data);                           // BLTU
```

## Severity
Medium — BLT and BLTU are used in loops and boundary checks.
A wrong comparison direction can cause:
- Loop termination conditions to fail
- Array bounds checks to pass incorrectly
- Security-sensitive comparisons to give wrong results
