# test_jal.s — JAL / JALR instruction test
# Tests: JAL saves link address, JALR returns, JALR LSB cleared

_start:
    # Test 1: JAL saves return address (pc+4) to rd
    jal  x10, jal_target
    # Should not reach here if JAL works
    beq  x0, x0, fail

jal_target:
    # x10 should be _start + 4 (the next instruction after JAL)
    # Verify x10 is nonzero
    beq  x10, x0, fail

    # Test 2: JALR uses x10 to return
    # Place return address in x10, then JALR to it
    auipc x11, 0
    addi  x11, x11, 16        # point to ret_target
    jalr  x12, 0(x11)          # jump, link x12
    beq   x0, x0, fail

ret_target:
    # x12 should be nonzero (link address)
    beq  x12, x0, fail

    # Test 3: JALR LSB clearing
    # Set x11 to odd address, JALR should clear LSB
    auipc x13, 0
    addi  x13, x13, 8          # aligned target
    ori   x14, x13, 1           # make it odd
    jalr  x15, 0(x14)           # should jump to x14 & ~1 = x13
    beq   x0, x0, fail

lsb_ok:

    # Test 4: JAL with rd=x0 (unconditional jump)
    jal  x0, skip
    beq  x0, x0, fail
skip:

pass:
    lui  x20, 0xFFFF0
    addi x1, x0, 1
    sw   x1, 0(x20)
    ebreak

fail:
    lui  x20, 0xFFFF0
    sw   x0, 0(x20)
    ebreak
