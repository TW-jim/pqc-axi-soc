# PQC AXI SoC

An AXI-integrated post-quantum cryptography accelerator project built around an NTT/INTT hardware core.

The project focuses on SoC-style integration, RTL verification, ASIC implementation, and architecture optimization. The original thesis NTT/INTT core is kept private; the public repository contains the AXI/control infrastructure, verification support, implementation configuration, and summarized results.

## Architecture

The public design includes:

- AXI4-Lite control/status registers
- AXI4 burst read loader
- AXI4 burst write writer
- Accelerator controller
- Input/output coefficient buffers
- Top-level AXI/accelerator integration

The private NTT/INTT accelerator processes four 23-bit coefficients per cycle and is connected through a private adapter.

## Verification

The integrated design was verified with self-checking RTL tests covering:

- NTT and INTT golden-vector checking
- NTT → INTT round-trip checking
- AXI backpressure
- Protocol stability during stalls
- Six consecutive accelerator transactions without a global reset

## V1 ASIC Baseline

V1 is intentionally used as a conservative reference implementation rather than an aggressively PPA-optimized design.

**Technology:** Nangate45  
**Clock constraint:** 10.0 ns / 100 MHz  
**Flow:** Yosys + OpenROAD Flow Scripts

| Metric | V1 Baseline |
|---|---:|
| Generic cells | 141,556 |
| Nangate45 mapped area | 269,731 um² |
| Core area | 897,281.84 um² |
| Final design area | 274,408 um² |
| Final utilization | 31% |
| Setup worst slack | +6.18018 ns |
| Hold worst slack | +0.0566224 ns |
| Setup / Hold TNS | 0 / 0 |
| Clock skew | ~0.0525 ns |
| Routed wirelength | 2,079,691 um |
| Via count | 886,097 |
| Detailed-route violations | 0 |
| Antenna violations | 0 |
| Final GDS | Generated locally |

The complete V1 flow reached:

**RTL → Synthesis → Floorplan → Placement → CTS → Routing → RC Extraction → Final GDS**

## Bottleneck Analysis

Generic synthesis showed that the original monolithic multi-port coefficient buffers dominate the SoC-side logic cost.

### V1 Generic Cell Breakdown

The following breakdown is derived from the Yosys synthesis results.  
Private thesis-related modules are aggregated into `Private NTT/INTT Acc` to avoid exposing the internal accelerator hierarchy.

| Module | Generic Cells | Share |
|---|---:|---:|
| Private NTT/INTT Acc | 66,169 | 46.74% |
| Input Buffer | 35,797 | 25.29% |
| Output Buffer | 37,546 | 26.52% |
| AXI Read Loader | 644 | 0.45% |
| AXI Write Writer | 484 | 0.34% |
| NTT Acc Control Top | 916 | 0.65% |
| **Total** | **141,556** | **100.00%** |

**Input + Output Buffers: 73,343 generic cells (51.81% of the full design).**

The input and output buffers therefore form the largest logic-cost component in V1, motivating the banked-buffer redesign in V2.

### Original Yosys Results

V1 input/output buffer synthesis statistics:

![V1 Input and Output Buffer Yosys statistics](V1_IO_Buffer_cells.png)

Full-design generic cell count:

![V1 total Yosys generic cell count](V1_Total_cells.png)

## V2 Plan

V2 introduces a **banked coefficient-buffer architecture**.

Evaluation is split into two phases:

1. **Controlled V1 vs V2 comparison**  
   V2 first uses the same technology, clock constraint, utilization, placement density, and flow settings as V1 so that architectural improvements can be compared fairly.

2. **PPA optimization**  
   After the controlled comparison, V2 will be further explored using clock-period, utilization, density, and timing-oriented implementation sweeps.

The final comparison will focus on area, timing, routing cost, congestion, and achievable frequency.

## Repository Notes

The following are intentionally kept private:

- Thesis NTT/INTT RTL
- Private integration adapters and testbenches
- Golden-vector files
- Synthesized private netlists
- ODB / DEF / GDS / SPEF / SDF artifacts
- Raw reports containing private hierarchy information

`asic/orfs/v1_baseline/Config.public.mk` documents the V1 OpenROAD configuration, but it is not standalone runnable without a user-supplied accelerator core and integration wrapper.

## Tools

- Verilog
- Verilator
- Yosys
- OpenROAD Flow Scripts
- Nangate45
- Git
