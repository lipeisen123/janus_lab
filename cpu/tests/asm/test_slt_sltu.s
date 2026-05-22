# test_slt_sltu.s — SLT/SLTU instruction test
# Tests: SLT and SLTU where signed and unsigned comparison differ
#
# Key: -1 (0xFFFFFFFF) < 0 — signed: true(1), unsigned: false(0)
#      -1 < 1            — signed: true(1), unsigned: false(0)
# Expected: x10(SLT -1,0)=1, x11(SLTU -1,0)=0, x12(SLT -1,1)=1, x13(SLTU -1,1)=0

    .section .text
    .globl _start
_start:
    addi x5, x0, -1           # x5 = 0xFFFFFFFF

    # Test 1: SLT -1 < 0 should be 1 (signed)
    slt  x10, x5, x0
    addi x6, x0, 1
    bne  x10, x6, fail

    # Test 2: SLTU -1 < 0 should be 0 (unsigned: 0xFFFFFFFF > 0)
    sltu x11, x5, x0
    bne  x11, x0, fail

    # Test 3: SLT -1 < 1 should be 1 (signed)
    addi x7, x0, 1
    slt  x12, x5, x7
    addi x6, x0, 1
    bne  x12, x6, fail

    # Test 4: SLTU -1 < 1 should be 0 (unsigned: 0xFFFFFFFF > 1)
    sltu x13, x5, x7
    bne  x13, x0, fail

    # Test 5: SLT 5 < 3 should be 0
    addi x8, x0, 5
    addi x9, x0, 3
    slt  x14, x8, x9
    bne  x14, x0, fail

    # Test 6: SLTU 5 < 3 should be 0
    sltu x15, x8, x9
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
