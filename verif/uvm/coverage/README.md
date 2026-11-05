# AXI4-Lite Functional Coverage

This directory documents the functional-coverage model used by the UVM verification environment for `rtl/bus/NTT_AXIL_Regs.v`.

The coverage collector samples transactions reconstructed by `AXIL_Monitor` through the UVM analysis path. This means the coverage model is based on activity observed at the DUT interface rather than directly sampling the sequence stimulus.

## Current Coverage Model

The first coverage model contains the following coverpoints and crosses:

| Coverage item | Definition | Bins |
|---|---|---:|
| `cp_op` | AXI-Lite read / write operation | 2 |
| `cp_addr` | CONTROL / STATUS / SRC_ADDR / DST_ADDR | 4 |
| `cp_strb` | All non-zero `WSTRB` values from `4'h1` through `4'hF` | 15 |
| `op_x_addr` | Operation × register address | 8 |
| `addr_x_strb` | Register address × write strobe | 60 |
| **Total** |  | **89** |

`cp_strb` is sampled only for write transactions. READ transactions therefore do not create meaningless `WSTRB=0` coverage activity.

## Regression Results

The constrained-random test executes 100 AXI-Lite transactions per seed. The regression currently randomizes:

- READ versus WRITE
- Register address among CONTROL, STATUS, SRC_ADDR, and DST_ADDR
- 32-bit write data
- Non-zero partial `WSTRB` patterns
- Write-channel ordering: AW/W together, AW first, or W first
- Inter-channel delay from 0 to 3 cycles

The first three constrained-random seeds completed without UVM errors or fatals.

| Test | Transactions | Functional Coverage | Result |
|---|---:|---:|---|
| Directed smoke | 6 | 16.85% | PASS |
| Random seed 1 | 100 | 83.15% (74/89) | PASS |
| Random seed 2 | 100 | 84.27% (75/89) | PASS |
| Random seed 3 | 100 | 86.52% | PASS |
| **Seeds 1-3 merged** | **300** | **100.0% (89/89)** | **CLOSED** |

All three constrained-random runs completed with:

- `UVM_ERROR = 0`
- `UVM_FATAL = 0`

The merged result demonstrates coverage closure for the **current 89-bin functional-coverage model**. It should not be interpreted as 100% coverage of every possible AXI-Lite protocol behavior or of the complete SoC.

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

`--coverage-user` is used for this stage so that the reported database contains the explicit SystemVerilog functional coverage model. RTL line, branch, expression, toggle, and FSM coverage are a separate code-coverage milestone.

## Run the Regression

Create a directory for generated coverage databases:

```bash
mkdir -p verif/uvm/coverage_data
```

Run the directed smoke test:

```bash
./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Base_Test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  +verilator+coverage+file+verif/uvm/coverage_data/base.dat
```

Run constrained-random seeds:

```bash
./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Random_Test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  +verilator+seed+1 \
  +verilator+coverage+file+verif/uvm/coverage_data/random_seed1.dat

./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Random_Test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  +verilator+seed+2 \
  +verilator+coverage+file+verif/uvm/coverage_data/random_seed2.dat

./obj_dir/uvm_axil/Vtb_Top \
  +UVM_TESTNAME=AXIL_Random_Test \
  +UVM_VERBOSITY=UVM_MEDIUM \
  +verilator+seed+3 \
  +verilator+coverage+file+verif/uvm/coverage_data/random_seed3.dat
```

## Inspect Individual Coverage

For example, inspect seed 1:

```bash
verilator_coverage \
  --filter-type covergroup \
  --report summary \
  verif/uvm/coverage_data/random_seed1.dat
```

The observed seed-1 result was:

```text
covergroup : 83.1% (74/89)
```

## Merge Coverage Across Seeds

Merge the three random coverage databases:

```bash
verilator_coverage \
  --write verif/uvm/coverage_data/random_merged.dat \
  verif/uvm/coverage_data/random_seed1.dat \
  verif/uvm/coverage_data/random_seed2.dat \
  verif/uvm/coverage_data/random_seed3.dat
```

Then report the merged functional coverage:

```bash
verilator_coverage \
  --filter-type covergroup \
  --report summary \
  verif/uvm/coverage_data/random_merged.dat
```

Current merged result:

```text
Coverage Summary:
  covergroup : 100.0% (89/89)
```

## Generate an Annotated Report

```bash
rm -rf verif/uvm/coverage_report

verilator_coverage \
  --filter-type covergroup \
  --annotate verif/uvm/coverage_report \
  --annotate-all \
  --annotate-points \
  verif/uvm/coverage_data/random_merged.dat
```

The generated `coverage_data/` databases and `coverage_report/` annotation directory are build artifacts and are intentionally excluded from Git. The coverage model source and this documentation are version-controlled instead.

## Current Scope and Next Extension

The current monitor reconstructs register transactions correctly for scoreboard and coverage sampling, but the transaction object published by the monitor does not yet reconstruct the original write-order metadata. As a result, AW/W ordering and delay are **not** part of the 89-bin coverage model described above.

The next functional-coverage extension is to reconstruct the actual AW and W handshake timing observed on the bus and cover:

- AW/W same-cycle transfer
- AW-first transfer
- W-first transfer
- Observed AW/W handshake gap
- Write order × register address
- Write order × observed handshake gap

This distinction is intentional: coverage should reflect what actually occurred at the DUT interface, not merely what the sequence requested.
