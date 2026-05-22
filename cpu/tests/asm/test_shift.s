# test_shift.s — SLL/SRL/SRA instruction test
# Tests: shift by 0, 1, 31; arithmetic vs logical right shift

_start:
    # Test 1: SLL 1 << 10 = 1024
    addi x5, x0, 1
    addi x6, x0, 10
    sll  x10, x5, x6
    addi x7, x0, 1024
    bne  x10, x7, fail

    # Test 2: SLL 1 << 0 = 1
    sll  x10, x5, x0
    addi x7, x0, 1
    bne  x10, x7, fail

    # Test 3: SRL 0x80000000 >> 31 = 1 (logical)
    lui  x5, 0x80000
    addi x6, x0, 31
    srl  x10, x5, x6
    addi x7, x0, 1
    bne  x10, x7, fail

    # Test 4: SRA 0x80000000 >>> 31 = 0xFFFFFFFF (arithmetic, sign extends)
    sra  x10, x5, x6
    addi x7, x0, -1
    bne  x10, x7, fail

    # Test 5: SRL 0x80000000 >> 0 = 0x80000000
    srl  x10, x5, x0
    bne  x10, x5, fail

    # Test 6: SRA positive number preserves sign
    addi x5, x0, 8
    addi x6, x0, 2
    sra  x10, x5, x6
    addi x7, x0, 2
    bne  x10, x7, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
