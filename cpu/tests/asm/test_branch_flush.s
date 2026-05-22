# test_branch_flush.s — Branch Flush Test
# Tests: wrong-path instructions must NOT write back to registers/memory
# Strategy: place a visible write on the wrong path — if it commits, flush is broken

_start:
    addi x10, x0, 1

    # Branch is always taken (x10 == 1)
    beq  x10, x10, target

    # WRONG PATH: these should be FLUSHED
    addi x20, x0, 99          # x20 = 99 (BAD if committed)
    addi x21, x0, 99          # x21 = 99 (BAD if committed)
    sw   x20, 0(x0)            # mem[0] = 99 (BAD if committed)

target:
    # Check that wrong-path writes did NOT happen
    bne  x20, x0, fail         # x20 should be 0 (initial) not 99
    bne  x21, x0, fail         # x21 should be 0 (initial) not 99

    # Check that mem[0] was NOT corrupted
    lw   x10, 0(x0)
    bne  x10, x0, fail

    # Test 2: JAL also flushes wrong-path
    jal  x0, j_target
    addi x22, x0, 99          # WRONG PATH — should NOT commit
j_target:
    bne  x22, x0, fail

    # Test 3: Backward branch to a loop, check no stale data
    addi x15, x0, 3
loop:
    addi x15, x15, -1
    bne  x15, x0, loop         # backward taken branch
    # x15 should be 0
    bne  x15, x0, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
