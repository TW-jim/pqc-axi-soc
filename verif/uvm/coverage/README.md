# AXI4-Lite Functional Coverage

This directory documents the functional-coverage model and regression flow used by the UVM verification environment for `rtl/bus/NTT_AXIL_Regs.v`.

The coverage subscriber samples transactions reconstructed by `AXIL_Monitor` through the UVM analysis path. Coverage is therefore based on activity actually observed at the DUT interface rather than directly sampling sequence intent.

## Verification Scope

The UVM environment targets the public **single-outstanding AXI4-Lite register slave**. The current regression covers:

- READ and WRITE accesses to CONTROL, STATUS, SRC_ADDR, and DST_ADDR
- Random 32-bit write data
- All 15 non-zero `WSTRB` patterns
- AW/W same-cycle, AW-first, and W-first transfers
- Observed AW/W handshake gaps
- AW, W, and AR request-side stalls
- B and R response backpressure
- Five-channel handshake/order and stalled-signal-stability checking
- Concurrent read/write activity
- Reset during partial write requests
- Reset while BVALID is stalled
- Reset while RVALID is stalled
- Scoreboard reference-model synchronization across reset
- Coverage-driven directed closure

This coverage model is intentionally specific to the implemented register block. A 100% result means all bins in the explicit model below were hit; it does not imply exhaustive coverage of every possible AXI4/AXI4-Lite system behavior or of the complete SoC.

## Current 166-Bin Coverage Model

| Coverage item | Definition | Bins |
|---|---|---:|
| `cp_op` | AXI-Lite READ / WRITE operation | 2 |
| `cp_addr` | CONTROL / STATUS / SRC_ADDR / DST_ADDR | 4 |
| `cp_strb` | All non-zero `WSTRB` values from `4'h1` through `4'hF` | 15 |
| `cp_write_order` | AW/W together / AW first / W first | 3 |
| `cp_handshake_gap` | Observed AW/W handshake-gap classes | 5 |
| write timing class | Legal order × gap timing classes | 9 |
| `op_x_addr` | Operation × register address | 8 |
| `addr_x_strb` | Register address × write strobe | 60 |
| `order_x_addr` | Observed write order × register address | 12 |
| `cp_aw_stall` | Observed AW request-stall classes | 4 |
| `cp_w_stall` | Observed W request-stall classes | 4 |
| `cp_b_stall` | Observed B response-stall classes | 4 |
| `cp_ar_stall` | Observed AR request-stall classes | 4 |
| `cp_r_stall` | Observed R response-stall classes | 4 |
| `order_x_b_stall` | Observed write order × B-stall class | 12 |
| `addr_x_r_stall` | Register address × R-stall class | 16 |
| **Total** |  | **166** |

The observed timing model distinguishes same-cycle AW/W handshakes from AW-first and W-first transfers. The driver generates stimulus intent, while the monitor independently reconstructs the order, handshake gap, and stall counts from the bus before coverage is sampled.

## Verified v6 Regression Results

The constrained-random test executes 100 AXI4-Lite transactions per seed. Three seeds were run, followed by directed protocol, stall/backpressure, concurrent-access, reset-stress, and targeted closure tests.

| Regression | Functional Coverage | Result |
|---|---:|---|
| Random seed 1 | 75.90% | PASS |
| Random seed 2 | 79.52% | PASS |
| Random seed 3 | 79.52% | PASS |
| `AXIL_Protocol_Test` | 43.37% | PASS |
| `AXIL_Channel_Stall_Test` | 24.70% | PASS |
| `AXIL_Concurrent_RW_Test` | 16.27% | PASS |
| `AXIL_Reset_Stress_Test` | 12.65% | PASS |
| `AXIL_Coverage_Closure_Test` | 15.06% | PASS |
| **Final merged** | **100.0% (166/166)** | **CLOSED** |

All executed v6 regressions used for the verified milestone completed with:

- `UVM_ERROR = 0`
- `UVM_FATAL = 0`

Individual percentages are not additive. Coverage closure is determined from the merged Verilator coverage databases.

## Directed Protocol and Stall Coverage

`AXIL_Protocol_Test` stresses the five AXI4-Lite channels and verifies:

- AW/W same-cycle transfers
- AW-first transfers with observed gaps
- W-first transfers with observed gaps
- B-channel backpressure
- R-channel backpressure
- Monitor reconstruction of actual bus-level timing
- Scoreboard consistency
- Protocol-checker handshake and stability behavior

The verified protocol regression completed with:

```text
handshakes AW=12 W=12 B=12 AR=16 R=16
stall cycles AW=0 W=0 B=18 AR=0 R=24
UVM_ERROR=0
UVM_FATAL=0
```

`AXIL_Channel_Stall_Test` explicitly creates request-side stalls while the previous response is outstanding. The verified regression completed with:

```text
handshakes AW=6 W=6 B=6 AR=6 R=6
stall cycles AW=6 W=6 B=3 AR=6 R=9
UVM_ERROR=0
UVM_FATAL=0
```

## Concurrent Read/Write Coverage

`AXIL_Concurrent_RW_Test` verifies that the AXI4-Lite read and write channel groups can make progress independently.

The directed cases include:

1. Holding a write response under B-channel backpressure while a read transaction proceeds.
2. Holding a read response under R-channel backpressure while a write transaction proceeds.

The verified regression completed with:

```text
handshakes AW=2 W=2 B=2 AR=2 R=2
stall cycles AW=0 W=0 B=3 AR=0 R=5
UVM_ERROR=0
UVM_FATAL=0
```

## Reset-Under-Activity Coverage

`AXIL_Reset_Stress_Test` applies reset during active protocol states, including:

- AW accepted while W has not yet arrived
- W accepted while AW has not yet arrived
- BVALID asserted while BREADY is low
- RVALID asserted while RREADY is low

The scoreboard observes `ARESETn` and resets its reference model together with the DUT. Post-reset readback checks verify that writable register state returns to zero.

The protocol-checker counters are also reset by `ARESETn`; therefore its final `post-final-reset` summary intentionally reports only activity after the last reset rather than the entire reset-stress test.

The reset-stress regression completed with `UVM_ERROR = 0` and `UVM_FATAL = 0`.

## Coverage-Driven Closure

Coverage closure was performed by inspecting uncovered bins rather than simply increasing the random-seed count.

The directed closure sequence verifies two partial-byte write cases:

### `SRC_ADDR × WSTRB = 4'hA`

```text
Write data : 0xA5C35A96
WSTRB      : 0xA
Readback   : 0xA5005A00
```

### `DST_ADDR × WSTRB = 4'hD`

```text
Write data : 0xC3A55A96
WSTRB      : 0xD
Readback   : 0xC3A50096
```

Both readbacks are checked by the scoreboard, so these are functional byte-enable checks rather than coverage-only stimulus.

The final expanded-model hole was `DST_ADDR × WSTRB = 4'hD`. After adding that directed case, the merged v6 regression reached:

```text
covergroup : 100.0% (166/166)
```

## One-Command v6 Regression

The repository provides `verif/uvm/run_regression.sh` as the public regression entry point. It rebuilds the UVM executable, runs all eight verified v6 regression jobs, checks each UVM report for zero errors and fatals, merges the coverage databases, and fails unless the final result is **100.0% (166/166)**.

```bash
chmod +x verif/uvm/run_regression.sh
./verif/uvm/run_regression.sh
```

`UVM_HOME` defaults to `$HOME/tools/uvm-2020-3.2-vlt` and can be overridden in the environment.

## Build for Functional Coverage

The UVM executable is built with Verilator user-coverage instrumentation enabled:

```bash
export UVM_HOME=$HOME/tools/uvm-2020-3.2-vlt

rm -rf obj_dir/uvm_axil

verilator \
  --binary \
  --timing \
  --coverage-user \
  -j 0 \
  -Wall \
  -Wno-fatal \
  +define+UVM_NO_DPI \
  +incdir+$UVM_HOME/src \
  +incdir+verif/uvm \
  $UVM_HOME/src/uvm_pkg.sv \
  verif/uvm/interfaces/AXIL_if.sv \
  verif/uvm/AXIL_Pkg.sv \
  rtl/bus/NTT_AXIL_Regs.v \
  verif/uvm/top/tb_Top.sv \
  --top-module tb_Top \
  --Mdir obj_dir/uvm_axil
```

`--coverage-user` is intentionally used for this milestone. The resulting database contains the explicit SystemVerilog functional-coverage model; RTL line, branch, expression, toggle, and FSM code coverage are separate metrics and are not claimed by the 166/166 result.

## Reproduce the v6 Coverage Regression

Create a clean output directory:

```bash
rm -rf verif/uvm/coverage_data/v6_full
mkdir -p verif/uvm/coverage_data/v6_full
```

Run directed protocol and stress tests:

```bash
./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Protocol_Test \
  +UVM_VERBOSITY=UVM_LOW \
  +verilator+coverage+file+verif/uvm/coverage_data/v6_full/protocol.dat

./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Channel_Stall_Test \
  +UVM_VERBOSITY=UVM_LOW \
  +verilator+coverage+file+verif/uvm/coverage_data/v6_full/channel_stall.dat

./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Concurrent_RW_Test \
  +UVM_VERBOSITY=UVM_LOW \
  +verilator+coverage+file+verif/uvm/coverage_data/v6_full/concurrent_rw.dat

./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Reset_Stress_Test \
  +UVM_VERBOSITY=UVM_LOW \
  +verilator+coverage+file+verif/uvm/coverage_data/v6_full/reset_stress.dat
```

Run three constrained-random seeds:

```bash
for seed in 1 2 3; do
    ./obj_dir/uvm_axil/Vtb_Top \
      +UVM_TESTNAME=AXIL_Random_Test \
      +UVM_VERBOSITY=UVM_LOW \
      +verilator+seed+$seed \
      +verilator+coverage+file+verif/uvm/coverage_data/v6_full/random_seed${seed}.dat
done
```

Run targeted coverage closure:

```bash
./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Coverage_Closure_Test \
  +UVM_VERBOSITY=UVM_LOW \
  +verilator+coverage+file+verif/uvm/coverage_data/v6_full/closure.dat
```

## Merge the v6 Coverage Databases

```bash
verilator_coverage \
  --write verif/uvm/coverage_data/v6_full/final_merged.dat \
  verif/uvm/coverage_data/v6_full/protocol.dat \
  verif/uvm/coverage_data/v6_full/channel_stall.dat \
  verif/uvm/coverage_data/v6_full/concurrent_rw.dat \
  verif/uvm/coverage_data/v6_full/reset_stress.dat \
  verif/uvm/coverage_data/v6_full/random_seed1.dat \
  verif/uvm/coverage_data/v6_full/random_seed2.dat \
  verif/uvm/coverage_data/v6_full/random_seed3.dat \
  verif/uvm/coverage_data/v6_full/closure.dat
```

Report the merged functional coverage:

```bash
verilator_coverage \
  --filter-type covergroup \
  --report summary \
  verif/uvm/coverage_data/v6_full/final_merged.dat
```

Verified result:

```text
Coverage Summary:
  covergroup : 100.0% (166/166)
```

## Inspect Remaining Holes

If a future coverage-model change causes the merged result to fall below 100%, generate an annotated report:

```bash
rm -rf verif/uvm/coverage_report/v6_full

verilator_coverage \
  --filter-type covergroup \
  --annotate verif/uvm/coverage_report/v6_full \
  --annotate-all \
  --annotate-points \
  --annotate-min 1 \
  verif/uvm/coverage_data/v6_full/final_merged.dat

grep -R -n -- "-000000" \
  verif/uvm/coverage_report/v6_full
```

Use the uncovered-bin report to add meaningful directed stimulus. Do not treat additional random seeds as a substitute for coverage analysis.

## Generated Artifacts

The following are generated regression artifacts and should remain excluded from Git:

```text
obj_dir/
verif/uvm/coverage_data/
verif/uvm/coverage_report/
coverage.dat
```

Only the UVM source, coverage model, regression documentation, and intentionally published reports should be version-controlled.
