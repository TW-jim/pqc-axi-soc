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

The input and output buffers together account for approximately **51.8% of the full generic cell count**, mainly due to FF/mux implementation of the multi-port storage structure.

This observation motivates the V2 redesign.

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
