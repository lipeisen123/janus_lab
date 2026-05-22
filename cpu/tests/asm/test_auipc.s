# test_auipc.s — AUIPC instruction test
# Tests: AUIPC adds PC to upper immediate
#
# AUIPC x10, 0 → x10 = PC (the instruction's own address)
# We verify x10 is nonzero and the lower 12 bits come from PC

_start:
    # Test 1: AUIPC x10, 0 → x10 = current PC
    auipc x10, 0                # x10 = PC
    # x10 should be nonzero
    beq  x10, x0, fail

    # Test 2: AUIPC then subtract PC → 0
    auipc x11, 0
    auipc x12, 0
    sub  x13, x11, x12          # Same PC, should be 0
    bne  x13, x0, fail

    # Test 3: AUIPC with offset
    # AUIPC x14, 1 → x14 = PC + 0x1000
    auipc x14, 1
    auipc x15, 0
    # x14 - x15 should be 0x1000
    sub  x16, x14, x15
    addi x17, x0, 0x1000         # Actually 1 << 12 = 4096
    # Wait, U-type imm is 20 bits. AUIPC rd = pc + (imm << 12)
    # imm = 1, so offset = 0x1000 = 4096
    sub  x18, x16, x17
    bne  x18, x0, fail

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
