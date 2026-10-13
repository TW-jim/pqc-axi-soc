# PQC AXI SoC

An AXI-integrated post-quantum cryptography accelerator project targeting compile-time ML-DSA (Dilithium) and ML-KEM (Kyber) NTT/INTT variants within a shared SoC-style integration framework.

The project focuses on AXI-based accelerator integration, RTL verification, ASIC implementation, architecture optimization, and PPA characterization. The Dilithium variant is currently integrated and verified through the complete RTL-to-GDS flow; Kyber integration is planned as the next implementation milestone. The original thesis NTT/INTT RTL is kept private, while the public repository contains the AXI/control infrastructure, verification support, implementation configuration, architecture-level documentation, and summarized results.

## Current Status

- **Dilithium / ML-DSA variant:** integrated, functionally verified, and implemented through RTL-to-GDS
- **V2 banked-buffer optimization:** completed and compared against the controlled V1 baseline
- **Fmax characterization:** ongoing; **500 MHz (2.0 ns)** has been verified as timing-clean and DRC-clean after the complete OpenROAD flow
- **PPA exploration:** ongoing
- **Kyber / ML-KEM variant:** planned next, reusing the shared AXI/control framework with algorithm-specific data-width and coefficient-ordering adaptation

## Architecture

The public SoC-side design includes:

- AXI4-Lite control/status registers
- AXI4 burst read engine (`AXI_Read_Loader`)
- AXI4 burst write engine (`AXI_Write_Writer`)
- Accelerator controller
- Input/output coefficient buffers
- Top-level AXI/accelerator integration

The current Dilithium implementation connects a private four-lane, 23-bit NTT/INTT accelerator through a private adapter. The architecture is intended to support a compile-time Kyber variant through the same AXI/control infrastructure, with algorithm-specific coefficient width, data packing, ordering, buffering, and core-adapter logic.

## Verification

The current Dilithium-integrated design was verified with self-checking RTL tests covering:

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
| Generic cells | 159,852 |
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

To provide a fair V1/V2 comparison, V1 was re-synthesized using the same Yosys version, synthesis script, and reporting method used for V2.

### V1 Generic Cell Breakdown

The following breakdown is derived from the controlled Yosys synthesis results.  
Private thesis-related modules are aggregated into `Private NTT/INTT Acc` to avoid exposing the internal accelerator hierarchy.

| Module | Generic Cells | Share |
|---|---:|---:|
| Private NTT/INTT Acc | 65,928 | 41.24% |
| Input Buffer | 54,865 | 34.32% |
| Output Buffer | 38,036 | 23.79% |
| AXI Read Loader | 321 | 0.20% |
| AXI Write Writer | 222 | 0.14% |
| NTT Acc Control Top | 480 | 0.30% |
| **Total** | **159,852** | **100.00%** |

**Input + Output Buffers: 92,901 generic cells (58.12% of the full design).**

The input and output buffers therefore form the largest logic-cost component in V1, motivating the banked-buffer redesign in V2.

### V1 Yosys Results

V1 input/output buffer synthesis statistics:

![V1 Input and Output Buffer Yosys statistics](V1_IO_Buffer_cells.png)

Full-design generic cell count:

![V1 total Yosys generic cell count](V1_Total_cells.png)

## V2 Banked Buffer Architecture

V2 replaces the original monolithic multi-port coefficient buffers with a banked storage architecture.

The redesign preserves the same logical coefficient storage capacity while reducing the multiplexing and routing logic required to support the accelerator access patterns.

The complete V2 Dilithium functional regression passed:

- Input Buffer standalone verification: 516 checks, 0 errors
- Output Buffer standalone verification: 260 checks, 0 errors
- Full AXI + real Dilithium end-to-end verification: 768 checks, 0 errors
- Randomized AXI backpressure regression: 781 checks, 0 errors
- Six continuous multi-transaction regression: 2,425 checks, 0 errors

### V2 Generic Cell Breakdown

The following results use the same Yosys version, synthesis script, and reporting method as the controlled V1 synthesis.

| Module | Generic Cells | Share |
|---|---:|---:|
| Private NTT/INTT Acc | 65,826 | 63.30% |
| Input Buffer | 19,429 | 18.68% |
| Output Buffer | 17,710 | 17.03% |
| AXI Read Loader | 321 | 0.31% |
| AXI Write Writer | 222 | 0.21% |
| NTT Acc Control Top | 480 | 0.46% |
| **Total** | **103,988** | **100.00%** |

**Input + Output Buffers: 37,139 generic cells (35.71% of the full design).**

The storage capacity remains unchanged. Both V2 buffers still contain 5,888 storage flip-flops, corresponding to the original 256 × 23-bit coefficient capacity of the current Dilithium implementation.

The reduction therefore comes primarily from the banked architecture reducing multi-port multiplexing and steering logic rather than from reducing the amount of stored data.

### V2 Yosys Results

V2 banked input/output buffer synthesis statistics:

![V2 Banked Input and Output Buffer Yosys statistics](V2_Banked_IO_Buffer_cells.png)

Full-design generic cell count:

![V2 total Yosys generic cell count](V2_Total_cells.png)

## Controlled V1 vs V2 Generic Synthesis Comparison

Both versions were synthesized using the same Yosys version, synthesis script, and reporting method.

| Metric | V1 | V2 Banked | Reduction |
|---|---:|---:|---:|
| Input Buffer Cells | 54,865 | 19,429 | **64.59%** |
| Input Buffer MUXes | 10,871 | 2,588 | **76.19%** |
| Output Buffer Cells | 38,036 | 17,710 | **53.44%** |
| Output Buffer MUXes | 20,217 | 3,057 | **84.88%** |
| Combined Buffer Cells | 92,901 | 37,139 | **60.02%** |
| Full Design Cells | 159,852 | 103,988 | **34.95%** |

The banked-buffer redesign reduces the generic logic cost of the two coefficient buffers by **60.02%**, while the complete design is reduced by **34.95%**.

The largest reductions occur in the multiplexing logic:

- Input Buffer MUX count: 10,871 → 2,588
- Output Buffer MUX count: 20,217 → 3,057

This confirms that the original bottleneck was primarily caused by the large multiplexing networks required by the monolithic multi-port buffer structures.

## Controlled V1 vs V2 Physical Comparison

V2 was then implemented using the same controlled physical-design conditions as V1:

- Nangate45 standard-cell platform
- 10 ns clock period
- 100 MHz target frequency
- 30% core-utilization target
- 0.60 placement density
- Same OpenROAD implementation flow

| Metric | V1 Baseline | V2 Banked | Change |
|---|---:|---:|---:|
| Generic Cells | 159,852 | 103,988 | **-34.95%** |
| Nangate45 Mapped Area | 269,731 um² | 248,113.894 um² | **-8.01%** |
| Final Design Area | 274,408 um² | 253,512 um² | **-7.61%** |
| Final Utilization | 31% | 31% | Same |
| Routed Wirelength | 2,079,691 um | 1,723,531 um | **-17.13%** |
| Via Count | 886,097 | 760,944 | **-14.12%** |
| Setup Worst Slack | +6.18018 ns | +6.00561 ns | -0.17457 ns |
| Hold Worst Slack | +0.0566224 ns | +0.0513977 ns | -0.00522 ns |
| Setup / Hold TNS | 0 / 0 | 0 / 0 | PASS |
| Clock Skew | ~0.0525 ns | ~0.0578 ns | Slightly higher |
| Detailed-route Violations | 0 | 0 | PASS |
| Antenna Violations | 0 | 0 | PASS |
| Reported Power | 35.7 mW | 34.6 mW | **-3.08%** |
| Final GDS | Generated locally | Generated locally | PASS |

The V2 banked-buffer architecture therefore provides measurable physical-design improvements in addition to the generic synthesis reduction.

At the same 100 MHz implementation target, V2 achieves:

- **7.61% lower final design area**
- **17.13% lower routed wirelength**
- **14.12% fewer vias**
- **3.08% lower reported power**

while maintaining:

- zero setup TNS
- zero hold TNS
- zero detailed-route violations
- zero antenna violations

The small reduction in timing slack is acceptable for this controlled comparison because both implementations still close timing with substantial positive margin.

## V2 PPA / Fmax Characterization

The controlled V1/V2 architecture comparison is complete. V2 is now being characterized across tighter clock constraints before the final PPA operating point is selected.

Verified full-flow results to date:

| Clock Period | Target Frequency | Setup WNS | Hold WNS | Final Design Area | Reported Power | DRC | Status |
|---:|---:|---:|---:|---:|---:|---:|---|
| 10.0 ns | 100.00 MHz | +6.00561 ns | +0.0513977 ns | 253,512 um² | 34.6 mW | 0 | PASS |
| 3.0 ns | 333.33 MHz | +0.664582 ns | +0.0411403 ns | 253,488 um² | 105 mW | 0 | PASS |
| 2.5 ns | 400.00 MHz | +0.382649 ns | +0.0365603 ns | 253,490 um² | 125 mW | 0 | PASS |
| 2.0 ns | 500.00 MHz | +0.0441963 ns | +0.0531033 ns | 253,962 um² | 156 mW | 0 | PASS |

At the current verified point, the V2 Dilithium implementation has completed the full OpenROAD flow at **500 MHz (2.0 ns)** with positive setup/hold slack, zero setup/hold TNS, zero detailed-route violations, and zero antenna violations.

This **500 MHz result is the highest verified timing-clean point so far, not yet the final reported Fmax**. Finer clock-period characterization is ongoing to determine the timing boundary.

The remaining PPA exploration includes:

1. **Fmax boundary characterization**  
   Continue tightening the clock constraint until adjacent timing-clean and failing points establish the implementation boundary.

2. **Core-utilization exploration**  
   Evaluate utilization targets to study the area, routability, and timing trade-offs.

3. **Placement-density exploration**  
   Vary placement density to evaluate congestion, wirelength, timing, and final implementation quality.

4. **Final PPA selection**  
   Retain both the maximum timing-clean implementation point and a balanced PPA operating point based on timing, area, routing, and reported power.

The 10 ns controlled result remains the V1/V2 architecture-comparison baseline and is not treated as the maximum achievable operating frequency.

## Next Milestones

- Complete Dilithium Fmax characterization
- Complete utilization / placement-density PPA exploration
- Select final Fmax and balanced-PPA implementation points
- Integrate the **Kyber / ML-KEM** compile-time variant using the shared AXI/control infrastructure
- Add Kyber-specific coefficient width, packing, ordering, buffering, and core-adapter logic
- Run Kyber functional verification and ASIC implementation analysis

## Repository Notes

The following are intentionally kept private:

- Thesis NTT/INTT RTL
- Private integration adapters and testbenches
- Golden-vector files
- Synthesized private netlists
- ODB / DEF / GDS / SPEF / SDF artifacts
- Raw reports containing private hierarchy information

`asic/orfs/v1_baseline/Config.public.mk` documents the V1 OpenROAD configuration, but it is not standalone runnable without a user-supplied accelerator core and integration wrapper.

The public repository is intended to demonstrate the SoC integration methodology, verification strategy, architecture optimization process, reproducible implementation setup, and summarized PPA results without publishing the private thesis accelerator implementation.

## Tools

- Verilog
- cocotb
- Verilator
- Yosys
- OpenROAD Flow Scripts
- Nangate45
- Git
