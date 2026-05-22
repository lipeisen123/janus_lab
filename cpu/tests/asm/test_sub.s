# test_sub.s — SUB instruction test
# Tests: SUB positive, SUB zero result, SUB negative result
#
# Expected: 20-8=12, 5-5=0, 0-1=0xFFFFFFFF(-1)
#            all checks pass → store 1 at 0xFFFF_0000

    .section .text
    .globl _start
_start:
    # Test 1: SUB 20 - 8 = 12
    addi x10, x0, 20
    addi x11, x0, 8
    sub  x12, x10, x11
    addi x13, x0, 12
    bne  x12, x13, fail

    # Test 2: SUB 5 - 5 = 0
    addi x10, x0, 5
    addi x11, x0, 5
    sub  x12, x10, x11
    bne  x12, x0, fail

    # Test 3: SUB 0 - 1 = 0xFFFFFFFF (-1)
    addi x10, x0, 0
    addi x11, x0, 1
    sub  x12, x10, x11
    addi x13, x0, -1
    bne  x12, x13, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
