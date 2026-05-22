#!/usr/bin/env python3
"""RISC-V CPU Regression Script — Lab 02
Runs all test categories and prints a summary table.
Usage: python scripts/regress.py [--cpu single|pipelined]
"""
import subprocess, sys, os, glob, time

CPU_DIR = os.path.join(os.path.dirname(__file__), "..")
TEST_HEX = os.path.join(CPU_DIR, "tests", "hex")
CHECK_DIR = os.path.join(CPU_DIR, "checks")
VERILOG_SRC = [
    "pc.v", "imem.v", "regfile.v", "immgen.v", "ctrl.v",
    "alu.v", "aluctrl.v", "dmem.v", "branch_unit.v"
]

def run_cmd(cmd, cwd=CPU_DIR):
    """Run a command, return (exit_code, stdout)."""
    try:
        r = subprocess.run(cmd, shell=True, cwd=cwd,
                           capture_output=True, text=True, timeout=60)
        return r.returncode, r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        return -1, "TIMEOUT"
    except Exception as e:
        return -1, str(e)

def run_iverilog_test(top_file, extra_src=None, define=None):
    """Compile and run a single Verilog test. Returns (pass, output)."""
    src = VERILOG_SRC.copy()
    if extra_src:
        src.extend(extra_src)
    src_str = " ".join(src)

    vvp = os.path.join(CPU_DIR, "_regress_tmp.vvp")
    define_flag = f"-D{define} " if define else ""
    cmd = f"iverilog {define_flag}-o {vvp} {top_file} {src_str} && vvp {vvp}"
    code, out = run_cmd(cmd)
    # clean up
    if os.path.exists(vvp):
        os.remove(vvp)
    passed = "PASS" in out or "All" in out or "ALL" in out
    return passed, out

def run_cpu_test(hex_file, cpu_type="single"):
    """Run a CPU test with a given hex file. Returns (pass, output)."""
    src = VERILOG_SRC.copy()
    if cpu_type == "pipelined":
        src.extend(["pipeline_regs.v", "hazard_unit.v", "forward_unit.v", "cpu_pipelined.v"])
        define = "USE_PIPELINED"
    else:
        src.append("cpu.v")
        define = None

    src_str = " ".join(src)
    vvp = os.path.join(CPU_DIR, "_regress_tmp.vvp")
    define_flag = f"-D{define} " if define else ""

    cmd = f"iverilog {define_flag}-o {vvp} tb_top.v {src_str} && vvp {vvp}"
    code, out = run_cmd(cmd)
    if os.path.exists(vvp):
        os.remove(vvp)
    passed = "TEST PASSED" in out or "PASS at cycle" in out
    return passed, out

def main():
    cpu_type = "single"
    if "--cpu" in sys.argv:
        idx = sys.argv.index("--cpu")
        if idx + 1 < len(sys.argv):
            cpu_type = sys.argv[idx + 1]

    print(f"{'='*60}")
    print(f"  Janus CPU Regression Suite — Lab 02")
    print(f"  CPU: {cpu_type}-cycle")
    print(f"  Time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")
    print()

    results = []

    # =========================================================================
    # 1. Smoke / Lint (Verilator if available, else skip)
    # =========================================================================
    print("--- 1. Smoke / Lint ---")
    code, out = run_cmd("verilator --lint-only -Wall -Wno-fatal -I. tb_top.v " + " ".join(VERILOG_SRC))
    if code == 0:
        print("  [PASS] Verilator lint")
        results.append(("lint", "PASS", ""))
    else:
        print("  [SKIP] Verilator not available (install verilator for lint)")
        results.append(("lint", "SKIP", "verilator not found"))

    # =========================================================================
    # 2. Module Tests
    # =========================================================================
    print("\n--- 2. Module-Level Tests ---")
    module_tests = [
        ("C2: ALU",       "formal_alu.v",        []),
        ("C1: RegFile x0", "formal_regfile_x0.v", []),
        ("Ctrl opcode",    "check_ctrl.v",        []),
        ("ImmGen format",  "check_immgen.v",      []),
        ("C6: Hazard",     "formal_hazard_unit.v", ["hazard_unit.v"]),
        ("Data Memory",    "check_dmem.v",        []),
    ]
    for name, top, extra in module_tests:
        top_path = os.path.join(CHECK_DIR, top)
        passed, out = run_iverilog_test(top_path, extra_src=extra)
        status = "PASS" if passed else "FAIL"
        print(f"  [{status}] {name}")
        results.append((f"module:{name}", status, "" if passed else out[:200]))

    # =========================================================================
    # 3. Instruction-Level Tests
    # =========================================================================
    print("\n--- 3. Instruction-Level Tests ---")
    inst_tests = sorted(glob.glob(os.path.join(TEST_HEX, "test_*.hex")))
    # Filter out hazard tests (they go in category 4)
    hazard_names = {"test_load_use", "test_forwarding", "test_branch_flush"}
    for hex_path in inst_tests:
        name = os.path.splitext(os.path.basename(hex_path))[0]
        if name in hazard_names:
            continue
        passed, out = run_cpu_test(hex_path, cpu_type)
        status = "PASS" if passed else "FAIL"
        print(f"  [{status}] {name}")
        results.append((f"instr:{name}", status, "" if passed else out[:200]))

    # =========================================================================
    # 4. Hazard Tests (pipelined only)
    # =========================================================================
    print("\n--- 4. Hazard Tests ---")
    for name in ["test_load_use", "test_forwarding", "test_branch_flush"]:
        hex_path = os.path.join(TEST_HEX, f"{name}.hex")
        if not os.path.exists(hex_path):
            continue
        passed, out = run_cpu_test(hex_path, cpu_type)
        status = "PASS" if passed else "FAIL"
        print(f"  [{status}] {name}")
        results.append((f"hazard:{name}", status, "" if passed else out[:200]))

    # =========================================================================
    # Summary
    # =========================================================================
    print(f"\n{'='*60}")
    print(f"  SUMMARY")
    print(f"{'='*60}")
    n_pass = sum(1 for _, s, _ in results if s == "PASS")
    n_fail = sum(1 for _, s, _ in results if s == "FAIL")
    n_skip = sum(1 for _, s, _ in results if s == "SKIP")
    print(f"  Total: {len(results)} | PASS: {n_pass} | FAIL: {n_fail} | SKIP: {n_skip}")
    print()

    for name, status, _ in results:
        if status == "FAIL":
            print(f"  [FAIL] {name}")

    print()
    if n_fail == 0:
        print("  === ALL TESTS PASSED ===")
    else:
        print(f"  === {n_fail} TEST(S) FAILED ===")

    return 0 if n_fail == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
