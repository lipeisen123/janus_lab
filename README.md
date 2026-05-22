# Janus Lab — RISC-V CPU

A tiny RISC-V RV32I CPU with formal verification, built for the Janus Lab course.

```
cpu/
├── *.v              # 14 RTL modules (single-cycle + 5-stage pipeline)
├── checks/          # 8 verification harnesses + bug injection
├── docs/            # specs, contracts, Hoare induction proof
├── tests/           # 13 assembly tests (asm + hex)
├── scripts/         # regression suite
├── Makefile         # one-command build & test
└── tb_top.v         # simulation testbench
```

### Quick Start

```bash
cd cpu
make sim                # simulate single-cycle CPU
make CPU=pipelined sim  # simulate pipelined CPU
make check-all          # run all verification checks
python scripts/regress.py --cpu single  # full regression suite
```
