# RISC-V CPU Project Makefile
# Supports: iverilog (default) and verilator
#
# Targets:
#   make CPU=single sim    — simulate single-cycle CPU
#   make CPU=pipelined sim — simulate pipelined CPU
#   make check-all         — run all formal contract checks
#   make check-alu         — C2: ALU operation correctness
#   make check-regfile     — C1: Register x0 invariant
#   make check-hazard      — C6: Load-use hazard detection
#   make check-ctrl        — Control unit opcode decode
#   make check-immgen      — Immediate generator format check
#   make check-dmem        — Data memory sub-word access
#   make check-bug         — Bug detection test (golden vs buggy)
#   make check-x0-induction — Hoare induction: x0 invariant proof
#   make regress           — Full regression suite (Lab 02)
#   make lint              — Verilator lint check
#   make yosys-check       — Yosys structural sanity check
#   make waves             — View waveform with gtkwave
#   make clean             — Remove generated files

SIM ?= iverilog
CPU ?= single

SRC = pc.v imem.v regfile.v immgen.v ctrl.v alu.v aluctrl.v dmem.v branch_unit.v

ifeq ($(CPU),pipelined)
	TOP = cpu_pipelined
	SRC += pipeline_regs.v hazard_unit.v forward_unit.v cpu_pipelined.v
	DEFINE = -DUSE_PIPELINED
else
	TOP = cpu
	SRC += cpu.v
endif

TB = tb_top.v
VVP = sim.vvp
VCD = dump.vcd

CHECKS_DIR = checks

.PHONY: sim clean waves check-all check-alu check-regfile check-hazard check-ctrl check-immgen check-dmem check-bug check-x0-induction lint yosys-check regress

# --- CPU Simulation ---
sim: $(SRC) $(TB)
ifeq ($(SIM),verilator)
	verilator --binary -j0 --trace $(DEFINE) $(TB) $(SRC) --top tb_top
	./obj_dir/Vtb_top
else
	iverilog $(DEFINE) -o $(VVP) $(TB) $(SRC)
	vvp $(VVP)
endif

# --- Waveform Viewer ---
waves:
	gtkwave $(VCD) &

# --- Lint ---
lint:
	verilator --lint-only -Wall -I. $(TB) $(SRC) 2>&1 || echo "Lint done (warnings above may be benign)"

# --- Yosys Synthesis Check ---
yosys-check:
	yosys -p 'read_verilog $(SRC); hierarchy -top $(TOP); proc; opt; check' 2>&1 || echo "Yosys check done"

# --- Module Tests ---

check-alu:
	iverilog -o $(CHECKS_DIR)/formal_alu.vvp $(CHECKS_DIR)/formal_alu.v alu.v
	vvp $(CHECKS_DIR)/formal_alu.vvp

check-regfile:
	iverilog -o $(CHECKS_DIR)/formal_regfile_x0.vvp $(CHECKS_DIR)/formal_regfile_x0.v regfile.v
	vvp $(CHECKS_DIR)/formal_regfile_x0.vvp

check-hazard:
	iverilog -o $(CHECKS_DIR)/formal_hazard_unit.vvp $(CHECKS_DIR)/formal_hazard_unit.v hazard_unit.v
	vvp $(CHECKS_DIR)/formal_hazard_unit.vvp

check-ctrl:
	iverilog -o $(CHECKS_DIR)/check_ctrl.vvp $(CHECKS_DIR)/check_ctrl.v ctrl.v
	vvp $(CHECKS_DIR)/check_ctrl.vvp

check-immgen:
	iverilog -o $(CHECKS_DIR)/check_immgen.vvp $(CHECKS_DIR)/check_immgen.v immgen.v
	vvp $(CHECKS_DIR)/check_immgen.vvp

check-dmem:
	iverilog -o $(CHECKS_DIR)/check_dmem.vvp $(CHECKS_DIR)/check_dmem.v dmem.v
	vvp $(CHECKS_DIR)/check_dmem.vvp

# --- Bug Detection ---
check-bug-golden:
	iverilog -o $(CHECKS_DIR)/tb_branch_golden.vvp $(CHECKS_DIR)/tb_branch_bug_detect.v branch_unit.v
	vvp $(CHECKS_DIR)/tb_branch_golden.vvp

check-bug-inject:
	iverilog -DINJECT_BUG -o $(CHECKS_DIR)/tb_branch_buggy.vvp $(CHECKS_DIR)/tb_branch_bug_detect.v $(CHECKS_DIR)/branch_unit_buggy.v
	vvp $(CHECKS_DIR)/tb_branch_buggy.vvp

check-bug: check-bug-golden check-bug-inject

check-x0-induction:
	iverilog -o $(CHECKS_DIR)/induction_x0.vvp $(CHECKS_DIR)/induction_x0.v regfile.v
	vvp $(CHECKS_DIR)/induction_x0.vvp

check-all: check-alu check-regfile check-hazard check-ctrl check-immgen check-dmem check-bug check-x0-induction

# --- Full Regression (Lab 02) ---
regress:
	python scripts/regress.py --cpu $(CPU)

# --- Cleanup ---
clean:
	rm -f $(VVP) $(VCD)
	rm -f $(CHECKS_DIR)/*.vvp
	rm -f _regress_tmp.vvp
	rm -rf obj_dir
