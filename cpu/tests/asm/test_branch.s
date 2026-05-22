# test_beq.s — BEQ/BNE/BGE/BLT branch test
# Tests: all 6 branch types, taken and not-taken

_start:
    # Test 1: BEQ equal → taken
    addi x5, x0, 5
    addi x6, x0, 5
    beq  x5, x6, t1_ok
    beq  x0, x0, fail
t1_ok:

    # Test 2: BEQ not equal → not taken
    addi x5, x0, 3
    addi x6, x0, 7
    beq  x5, x6, fail

    # Test 3: BNE not equal → taken
    bne  x5, x6, t3_ok
    beq  x0, x0, fail
t3_ok:

    # Test 4: BNE equal → not taken
    addi x5, x0, 9
    addi x6, x0, 9
    bne  x5, x6, fail

    # Test 5: BLT -5 < 3 → taken (signed)
    addi x5, x0, -5
    addi x6, x0, 3
    blt  x5, x6, t5_ok
    beq  x0, x0, fail
t5_ok:

    # Test 6: BLT 10 < 3 → not taken
    addi x5, x0, 10
    addi x6, x0, 3
    blt  x5, x6, fail

    # Test 7: BGE 10 >= 3 → taken
    bge  x5, x6, t7_ok
    beq  x0, x0, fail
t7_ok:

    # Test 8: BGE 3 >= 10 → not taken
    addi x5, x0, 3
    addi x6, x0, 10
    bge  x5, x6, fail

    # Test 9: BLTU -1 < 0 → not taken (unsigned: 0xFFFFFFFF > 0)
    addi x5, x0, -1
    bltu x5, x0, fail

    # Test 10: BGEU -1 >= 0 → taken (unsigned)
    bgeu x5, x0, t10_ok
    beq  x0, x0, fail
t10_ok:

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
