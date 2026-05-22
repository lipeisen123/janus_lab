# test_forwarding.s — Forwarding (RAW Hazard) Test
# Tests: back-to-back ALU → forwarding from EX/MEM and MEM/WB
# Without forwarding: second instruction uses stale register file data
# With forwarding:    results are bypassed correctly

_start:
    # Test 1: EX/MEM forwarding
    # addi x10, x0, 5      → x10 = 5
    # addi x11, x10, 3     → needs x10 from EX/MEM forwarding → x11 = 8
    addi x10, x0, 5
    addi x11, x10, 3
    addi x7, x0, 8
    bne  x11, x7, fail

    # Test 2: MEM/WB forwarding
    # Three back-to-back: second needs EX/MEM, third needs MEM/WB
    addi x10, x0, 10
    addi x10, x10, 5        # x10 = 15 (needs EX/MEM fwd from prev)
    addi x10, x10, 5        # x10 = 20 (needs MEM/WB fwd)
    addi x7, x0, 20
    bne  x10, x7, fail

    # Test 3: Forwarding over x0 — should NOT forward from x0
    add  x0, x10, x10        # writes to x0 (ignored)
    addi x12, x0, 99         # x12 = 99, shouldn't get forwarded data
    addi x7, x0, 99
    bne  x12, x7, fail

    # Test 4: Priority — EX/MEM wins over MEM/WB
    addi x13, x0, 100
    addi x13, x13, 1         # x13 = 101 (EX/MEM)
    addi x13, x13, 1         # x13 = 102 (needs EX/MEM(101) not MEM/WB(100))
    addi x7, x0, 102
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
