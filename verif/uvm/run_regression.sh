#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
UVM_HOME="${UVM_HOME:-$HOME/tools/uvm-2020-3.2-vlt}"
BUILD_DIR="${BUILD_DIR:-obj_dir/uvm_axil}"
COV_DIR="verif/uvm/coverage_data/v6_full"
LOG_DIR="verif/uvm/regression_logs/v6_full"
SIM="$BUILD_DIR/Vtb_Top"
EXPECTED_BINS=166
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command '$1' was not found in PATH." >&2
        exit 1
    fi
}
check_uvm_log() {
    local log_file="$1"
    local label="$2"
    if ! grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0' "$log_file"; then
        echo "ERROR: $label did not finish with UVM_ERROR = 0." >&2
        exit 1
    fi
    if ! grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0' "$log_file"; then
        echo "ERROR: $label did not finish with UVM_FATAL = 0." >&2
        exit 1
    fi
}
run_test() {
    local test_name="$1"
    local label="$2"
    local coverage_file="$3"
    shift 3
    local log_file="$LOG_DIR/${label}.log"
    echo
    echo "============================================================"
    echo "RUN: $label ($test_name)"
    echo "============================================================"
    set +e
    "$SIM" \
        "+UVM_TESTNAME=$test_name" \
        +UVM_VERBOSITY=UVM_LOW \
        "$@" \
        "+verilator+coverage+file+$coverage_file" \
        2>&1 | tee "$log_file"
    local sim_status=${PIPESTATUS[0]}
    set -e
    if ((sim_status != 0)); then
        echo "ERROR: $label exited with status $sim_status." >&2
        exit "$sim_status"
    fi
    check_uvm_log "$log_file" "$label"
    echo "PASS: $label"
}
require_command verilator
require_command verilator_coverage
if [[ ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
    echo "ERROR: UVM package not found at '$UVM_HOME/src/uvm_pkg.sv'." >&2
    echo "Set UVM_HOME to the installed UVM 2020.3.2-vlt directory." >&2
    exit 1
fi
echo "Repository : $ROOT_DIR"
echo "UVM_HOME   : $UVM_HOME"
echo "Build dir  : $BUILD_DIR"
echo "Coverage   : $COV_DIR"
echo "Logs       : $LOG_DIR"
rm -rf "$BUILD_DIR" "$COV_DIR" "$LOG_DIR"
mkdir -p "$COV_DIR" "$LOG_DIR"
echo
echo "============================================================"
echo "BUILD: AXI4-Lite UVM regression"
echo "============================================================"
verilator \
    --binary \
    --timing \
    --coverage-user \
    -j 0 \
    -Wall \
    -Wno-fatal \
    +define+UVM_NO_DPI \
    "+incdir+$UVM_HOME/src" \
    +incdir+verif/uvm \
    "$UVM_HOME/src/uvm_pkg.sv" \
    verif/uvm/interfaces/AXIL_if.sv \
    verif/uvm/AXIL_Pkg.sv \
    rtl/bus/NTT_AXIL_Regs.v \
    verif/uvm/top/tb_Top.sv \
    --top-module tb_Top \
    --Mdir "$BUILD_DIR"
run_test \
    AXIL_Protocol_Test \
    protocol \
    "$COV_DIR/protocol.dat"
run_test \
    AXIL_Channel_Stall_Test \
    channel_stall \
    "$COV_DIR/channel_stall.dat"
run_test \
    AXIL_Concurrent_RW_Test \
    concurrent_rw \
    "$COV_DIR/concurrent_rw.dat"
run_test \
    AXIL_Reset_Stress_Test \
    reset_stress \
    "$COV_DIR/reset_stress.dat"
for seed in 1 2 3; do
    run_test \
        AXIL_Random_Test \
        "random_seed${seed}" \
        "$COV_DIR/random_seed${seed}.dat" \
        "+verilator+seed+$seed"
done
run_test \
    AXIL_Coverage_Closure_Test \
    closure \
    "$COV_DIR/closure.dat"
echo
echo "============================================================"
echo "MERGE: functional coverage"
echo "============================================================"
verilator_coverage \
    --write "$COV_DIR/final_merged.dat" \
    "$COV_DIR/protocol.dat" \
    "$COV_DIR/channel_stall.dat" \
    "$COV_DIR/concurrent_rw.dat" \
    "$COV_DIR/reset_stress.dat" \
    "$COV_DIR/random_seed1.dat" \
    "$COV_DIR/random_seed2.dat" \
    "$COV_DIR/random_seed3.dat" \
    "$COV_DIR/closure.dat"
SUMMARY_FILE="$LOG_DIR/coverage_summary.txt"
verilator_coverage \
    --filter-type covergroup \
    --report summary \
    "$COV_DIR/final_merged.dat" \
    | tee "$SUMMARY_FILE"
if ! grep -Eq "covergroup[[:space:]]*:[[:space:]]*100\\.0%[[:space:]]*\\(${EXPECTED_BINS}/${EXPECTED_BINS}\\)" "$SUMMARY_FILE"; then
    echo "ERROR: expected 100.0% (${EXPECTED_BINS}/${EXPECTED_BINS}) functional coverage." >&2
    exit 1
fi
echo
echo "============================================================"
echo "PASS: v6 AXI4-Lite UVM regression"
echo "============================================================"
echo "All directed and constrained-random tests:"
echo "  UVM_ERROR = 0"
echo "  UVM_FATAL = 0"
echo "Functional coverage:"
echo "  100.0% (${EXPECTED_BINS}/${EXPECTED_BINS})"
echo
echo "Coverage database: $COV_DIR/final_merged.dat"
echo "Regression logs  : $LOG_DIR"
