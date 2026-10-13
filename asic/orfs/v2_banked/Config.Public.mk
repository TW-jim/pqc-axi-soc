# AI-generated comments
# ============================================================
# PQC AXI SoC
# V2 Banked Buffer - Public OpenROAD Configuration
#
# This file documents the physical-design configuration used
# for the controlled V1/V2 comparison.
#
# The private thesis NTT/INTT accelerator RTL and private
# integration wrappers are intentionally omitted.
#
# This configuration is therefore documentation-oriented and
# is NOT standalone runnable without a user-supplied
# accelerator core and integration wrapper.
# ============================================================
# ------------------------------------------------------------
# Platform
# ------------------------------------------------------------
export PLATFORM = nangate45
# ------------------------------------------------------------
# Design
# ------------------------------------------------------------
# The actual project uses a private integration top containing
# the public AXI/control logic and a private NTT/INTT core.
export DESIGN_NAME = NTT_Acc_Dilithium_Private_Top
export DESIGN_NICKNAME = pqc_axi_dilithium_v2
export FLOW_VARIANT = controlled_v2
# ------------------------------------------------------------
# Project root
# ------------------------------------------------------------
export PQC_ROOT = $(abspath $(dir $(DESIGN_CONFIG))/../../..)
# ------------------------------------------------------------
# Public RTL sources
#
# Private thesis-related RTL and private integration wrappers
# are intentionally not listed here.
# ------------------------------------------------------------
export VERILOG_FILES = \
    $(PQC_ROOT)/rtl/bus/NTT_AXIL_Regs.v \
    $(PQC_ROOT)/rtl/bus/AXI_Read_Loader.v \
    $(PQC_ROOT)/rtl/bus/AXI_Write_Writer.v \
    $(PQC_ROOT)/rtl/accel/Input_Buffer.v \
    $(PQC_ROOT)/rtl/accel/Output_Buffer.v \
    $(PQC_ROOT)/rtl/accel/Acc_Controller.v \
    $(PQC_ROOT)/rtl/accel/NTT_Acc_Control_Top.v \
    $(PQC_ROOT)/rtl/accel/NTT_Acc_Top.v
# ------------------------------------------------------------
# Timing constraints
#
# Controlled V1/V2 comparison:
#
#   Clock period     : 10.0 ns
#   Target frequency : 100 MHz
#
# V1 and V2 use the same timing constraint.
# ------------------------------------------------------------
export SDC_FILE =  $(PQC_ROOT)/asic/orfs/v2_banked/Constraint.sdc
# ------------------------------------------------------------
# Memory synthesis
#
# Kept identical to the V1 controlled baseline.
# ------------------------------------------------------------
export SYNTH_MEMORY_MAX_BITS = 8192
export SYNTH_MOCK_LARGE_MEMORIES = 0
# ------------------------------------------------------------
# Floorplan / placement
#
# Kept identical to the V1 controlled baseline so that the
# physical effect of the banked-buffer architecture can be
# evaluated fairly.
# ------------------------------------------------------------
export CORE_UTILIZATION = 30
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.60
# ------------------------------------------------------------
# Timing-flow configuration
# ------------------------------------------------------------
export TNS_END_PERCENT = 100
# ============================================================
# Reproduction Note
#
# This public configuration intentionally excludes the private
# thesis NTT/INTT accelerator and its integration wrappers.
#
# To reproduce the complete flow, provide an accelerator core
# with a compatible interface and an integration top, then add
# those RTL sources to VERILOG_FILES.
# ============================================================