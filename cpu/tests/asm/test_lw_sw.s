# test_lw_sw.s — LW/SW instruction test
# Tests: store word then load word to same address

_start:
    # Test 1: SW then LW — value should round-trip
    addi x5, x0, 0x100       # base address = 256
    addi x6, x0, 0x5555
    slli x6, x6, 16
    addi x6, x6, 0x555       # x6 = 0x55555555
    sw   x6, 0(x5)            # mem[256] = 0x55555555
    lw   x10, 0(x5)           # x10 = mem[256]
    sub  x11, x10, x6
    bne  x11, x0, fail

    # Test 2: SW to different address
    addi x5, x0, 0x104
    addi x7, x0, -1
    sw   x7, 0(x5)            # mem[260] = 0xFFFFFFFF
    lw   x12, 0(x5)
    addi x8, x0, -1
    bne  x12, x8, fail

    # Test 3: First address not corrupted
    addi x5, x0, 0x100
    lw   x10, 0(x5)
    bne  x10, x6, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
