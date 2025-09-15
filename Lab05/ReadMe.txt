Lab05

這次課主要介紹 Macro 與 SRAM。老師講 Soft/Firm/Hard Macro 的差別，尤其 Hard Macro 固定布線，可搬移或翻轉但不能改內部設計，挺新鮮。SRAM 部分讓我理解單埠/雙埠、OE/CS/WEB 控制，以及 timing 注意事項。作業讓我第一次用 Memory Compiler 生成 SRAM，整合到 RTL 裡，每個小細節都會影響時序。  

作業是 Motion Vector Difference Matching (MVDM)：先接收 L0/L1 影像存 SRAM，再算 BI_8x8，最後 Mirror MVD Matching 計算 SAD 找最小值輸出。流程像流水線，每個步驟 timing 都要小心。  

這次我主要練 testbench，驗證資料正確性，透過 debug 理解 SRAM、BI 和 SAD 的計算方式。整體收穫是實際操作 Macro、SRAM、Memory Compiler，並體會 testbench 在驗證流程的重要性，對理解硬體設計流程幫助很大。

Algorithm: 

# MVDM Module Algorithm Notes (English Version)

## Module Overview
- Module Name: MVDM
- Function: Takes two input images and motion vectors (MV), computes SAD (Sum of Absolute Difference) for each block using Bilinear Interpolation (BI)
- Main Signals:
    - Inputs: clk, rst_n, in_valid, in_valid2, in_data[11:0]
    - Outputs: out_valid, out_sad
- Internals: Uses multiple Block RAMs (BI Memory) and image buffers (Img Memory)

---

## FSM (Finite State Machine)
| State | Description |
|-------|-------------|
| IDLE | Wait for image or MV input |
| IN_IMG_0 | Input first image |
| IN_IMG_1 | Input second image |
| IN_MV | Input motion vectors |
| BI_LOAD_FIRST_0 | BI L0 initial load |
| BI_COMPUTE_0 | BI L0 computation (4-point interpolation) |
| BI_LOAD_FIRST_1 | BI L1 initial load |
| BI_COMPUTE_1 | BI L1 computation |
| SAD | Calculate Sum of Absolute Difference |
| OUT | Output the result |

- `next_state` determined by `current_state` and counter values
- counter1, counter2: used for row/column traversal
- counter3: used for BI internal point iteration
- counter4: used for BI row iteration or SAD accumulation

---

## Memory Control
### BI Memory (DI/DO/Addr/WEB)
- `DI_BI_0~3` = fp0*p0 + fp1*p1 + fp2*p2 + fp3*p3 → interpolation result
- `Addr_BI_0~3` = counter_3 + 10*counter_4 → corresponding BI block address
- `WEB_BI_0~3` = 0 for write, 1 otherwise

### Image Memory
- `Addr_first_Img` / `Addr_second_Img` = {counter1_Lx, counter2_Lx} → image coordinates
- `DI_first_Img` / `DI_second_Img` = in_data[11:4]
- `WEB_first` / `WEB_second` control write enable

---

## Bilinear Interpolation Algorithm
### L0 / L1 variables
- f0, f1: fractional parts (weights)
- fp0 = 256 - f0_span - f1_span + f0*f1
- fp1 = f0_span - f0*f1
- fp2 = f1_span - f0*f1
- fp3 = f0*f1
- p0~p3: pixel values (previous_node / DO_first_Img)
- DI_BI = fp0*p0 + fp1*p1 + fp2*p2 + fp3*p3 → BI output

### Previous Node Buffer
- previous_node_0[0:10] / previous_node_1[0:10]
- Stores previous row interpolation results for next row computation

---

## Motion Vector (MV) Control
- Mv_0 / Mv_1 = [2x2] matrix
- counter1 → x index, counter2 → y index
- index_L0 / index_L1 → used to offset BI Block Memory addresses

---

## SAD Computation
- SAD_0 / SAD_1 accumulates absolute difference of BI results
- Final output: out_sad
- accumulation_0 / accumulation_1 → intermediate accumulations
- debug signals allow observation of intermediate results

---

## Counter Summary
- counter1 / counter2 → row/column traversal
- counter3 → BI internal point iteration
- counter4 → BI row iteration or SAD accumulation
- counter1_L0/L1, counter2_L0/L1 → MV offset computation
- counter1_SAD_L0/L1, counter2_SAD_L0/L1 → SAD offset

---

## Overall Flow
1. IDLE: wait for image or MV input
2. IN_IMG_0: input first image
3. IN_IMG_1: input second image
4. IN_MV: input motion vectors
5. BI_LOAD_FIRST_0: BI L0 load
6. BI_COMPUTE_0: BI L0 compute
7. BI_LOAD_FIRST_1: BI L1 load
8. BI_COMPUTE_1: BI L1 compute
9. SAD: accumulate SAD
10. OUT: output result
