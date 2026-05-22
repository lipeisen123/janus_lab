# test_add.s — ADD instruction test
# Tests: ADD positive, ADD with zero, ADD overflow wrap
#
# Expected: x1 = 8+3 = 11, x2 = -1+1 = 0, x3 = 0xFFFFFFFF+1 = 0
#            all checks pass → store 1 at 0xFFFF_0000

    .section .text
    .globl _start
_start:
    # Test 1: ADD 8 + 3 = 11
    addi x10, x0, 8
    addi x11, x0, 3
    add  x12, x10, x11       # x12 = 11
    addi x13, x0, 11
    bne  x12, x13, fail

    # Test 2: ADD -1 + 1 = 0
    addi x10, x0, -1
    addi x11, x0, 1
    add  x12, x10, x11       # x12 = 0
    bne  x12, x0, fail

    # Test 3: ADD overflow 0xFFFFFFFF + 1 = 0
    lui  x10, 0xFFFFF        # x10 upper 20 = 0xFFFFF
    addi x10, x10, -1        # x10 = 0xFFFFFFFF
    addi x11, x0, 1
    add  x12, x10, x11       # x12 = 0 (wraps)
    bne  x12, x0, fail

    # Test 4: ADD x0, rs1, rs2 — writes to x0 silently ignored
    add  x0, x10, x11        # x0 should stay 0
    # implicit: x0 is always 0

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1           # PASS sentinel
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)          # FAIL sentinel
    ebreak
