# test_logic.s — AND/OR/XOR instruction test
# Tests: bitwise operations with alternating bit patterns

_start:
    # Test 1: AND 0xFF00FF00 & 0xF0F0F0F0 = 0xF000F000
    lui  x5, 0xFF00F
    addi x5, x5, 0xF00
    # x5 = 0xFF00FF00
    lui  x6, 0xF0F0F
    addi x6, x6, 0xF0F
    # x6 = 0xF0F0F0F0
    and  x10, x5, x6
    lui  x7, 0xF000F
    bne  x10, x7, fail

    # Test 2: OR 0xFF000000 | 0x00FF0000 = 0xFFFF0000
    lui  x5, 0xFF000
    lui  x6, 0x00FF0
    or   x10, x5, x6
    lui  x7, 0xFFFF0
    bne  x10, x7, fail

    # Test 3: XOR 0xFFFF0000 ^ 0xFFFFFFFF = 0x0000FFFF
    lui  x5, 0xFFFF0
    addi x6, x0, -1
    xor  x10, x5, x6
    # x10 should be 0x0000FFFF
    srai x10, x10, 16
    addi x7, x0, -1
    bne  x10, x7, fail

    # Test 4: AND with self = self
    and  x10, x5, x5
    bne  x10, x5, fail

    # Test 5: OR with zero = self
    or   x10, x5, x0
    bne  x10, x5, fail

    # Test 6: XOR with self = 0
    xor  x10, x5, x5
    bne  x10, x0, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
