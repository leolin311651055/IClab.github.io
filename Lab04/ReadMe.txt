Lab04

這次課核心還是 IP 運用，聚焦 Advanced Sequential Circuit Design，重點在 Timing / Setup-Hold / Pipeline，以及 DesignWare IP 的使用。老師講了 D Flip-Flop 的 timing 概念（setup/hold、propagation/contamination delay），示範如何檢查與修正 timing violation。Pipeline 的重要性透過 area vs timing trade-off 案例呈現得很直觀。  

作業是 Two-Head Attention 模組，雖然簡化了 token 數與 embedding 維度，但流程完整：算 K/Q/V、分頭、計算 attention、concat、linear projection。挑戰在完全對齊 raster scan order，以及 in_valid/out_valid、reset、latency 的 timing 控制。  

DesignWare IP 的使用讓我更直觀體會到，現成 IP 如何幫助提升效率、控制 area 與 timing。

Algorithm: 

//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise      : Two Head Attention
//   Author              : Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// Module: ATTN
// Description:
//  This module implements a Two-Head Attention computation using IEEE-754
//  single-precision floating-point arithmetic. The design uses multiple
//  pipeline stages and dedicated floating-point IPs for multiplication,
//  addition, division, and exponentiation.
//
// Ports:
//  Inputs:
//   - clk        : Clock signal
//   - rst_n      : Active-low reset
//   - in_valid   : Input data valid
//   - in_str     : Input data stream
//   - q_weight   : Query weight
//   - k_weight   : Key weight
//   - v_weight   : Value weight
//   - out_weight : Output weight
//  Outputs:
//   - out_valid  : Output data valid
//   - out        : Output data stream
//
// Internal Features:
//  - Floating-point multiply, add, divide, and exponent modules (DW_fp_* IPs)
//  - Multi-stage FSM for input, calculation, and output
//  - Supports two-head attention with intermediate score computation
//  - Implements pipelined computation for improved throughput
//
// Notes:
//  - IEEE floating point parameters defined at top
//  - Multi-dimensional registers store input, weight, score, and head values
//  - Counters control FSM stage progression and data indexing
//  - Exp, Multiply, Add, and Div operations mapped to dedicated IP instances
//
// FSM States:
//  - IDLE    : Waiting for input
//  - IN      : Receiving input data
//  - CAL_1..5: Computation stages
//  - OUT     : Output stage
//
// Usage:
//  - Instantiate ATTN module in top-level design
//  - Provide input weights and data stream
//  - Monitor out_valid and out for results
