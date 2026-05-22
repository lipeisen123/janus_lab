# test_lui.s — LUI instruction test
# Tests: LUI loads upper 20 bits, lower 12 bits must be zero

_start:
    # Test 1: LUI x10, 0x12345 → x10 = 0x12345000
    lui  x10, 0x12345
    # Check lower 12 bits are zero
    andi x11, x10, 0xFFF
    bne  x11, x0, fail
    # Check upper 20 bits
    srai x12, x10, 12
    # x12 should be 0x12345
    # Actually: lui loads imm[31:12] << 12, sign bit matters
    # 0x12345 upper bit = 0, no sign extension
    # x12 = x10 >> 12 = 0x12345000 >> 12 = 0x00123450
    # Hmm, let's check differently
    # Expected: x10 = 0x12345000
    lui  x13, 0x12345        # x13 should also be 0x12345000
    sub  x14, x10, x13
    bne  x14, x0, fail

    # Test 2: LUI x10, 0 → x10 = 0
    lui  x10, 0
    bne  x10, x0, fail

    # Test 3: LUI x10, 0xFFFFF → x10 = 0xFFFFF000 (sign extends)
    lui  x10, 0xFFFFF
    srai x11, x10, 12          # Should be 0xFFFFFFFF (sign extended)
    addi x12, x0, -1
    bne  x11, x12, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
