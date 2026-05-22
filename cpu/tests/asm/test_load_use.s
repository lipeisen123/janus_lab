# test_load_use.s — Load-Use Hazard Test
# Tests: LW followed immediately by dependent ADD → must stall 1 cycle
# If the stall works: x10 = 42 (loaded value), x11 = 84 (42*2)
# If no stall:      x11 consumes stale data (x10 before LW = 0) → x11 = 0

_start:
    # Setup: store 42 at address 256
    addi x5, x0, 0x100
    addi x6, x0, 42
    sw   x6, 0(x5)

    # Load-use sequence: LW then use immediately
    lw   x10, 0(x5)         # EX=MEM in next cycle: x10 not ready
    addi x11, x10, 42       # Needs x10, must stall 1 cycle

    # Verify: x10 should be 42, x11 should be 84
    addi x7, x0, 42
    bne  x10, x7, fail
    addi x7, x0, 84
    bne  x11, x7, fail

    # Second load-use: LW → ADD (reg to reg)
    addi x5, x0, 0x104
    addi x6, x0, 0x123
    sw   x6, 0(x5)
    lw   x12, 0(x5)
    add  x13, x12, x12       # x13 = x12 + x12, needs load-use stall
    slli x7, x6, 1           # x7 = 0x123 << 1 = 0x246
    bne  x13, x7, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
