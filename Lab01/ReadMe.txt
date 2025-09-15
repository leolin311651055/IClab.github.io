Lab01

這次作業主要讓我們熟悉問題拆解與演算法設計流程，要求針對指定問題設計並實作可行程式，理解如何將問題轉化為演算法。作業過程中，我練習了邏輯思考、程式設計技巧，並體會演算法效率的重要性，同時建立了使用 Verilog 設計組合電路的基礎概念。  

最具挑戰的是設計高效率演算法，需兼顧正確性與時間、空間複雜度。我最後選擇用 if 判斷列出所有可能排列，成功涵蓋所有情況，performance 獲得 24/30。這讓我體會到，即使不是最理想的方法，靈活應用策略也能取得不錯成果。

Algorithm: 

/**************************************************************************
 * MODULE      : HF (Huffman Encoder / Frequency Sort)
 * FILE NAME   : HF.v
 * VERSION     : 1.0
 * DATE        : 2025/09/15
 * AUTHOR      : Leo Lin
 * DESCRIPTION : Implements a combinational Huffman encoding logic based
 *               on input symbol frequencies. The design sorts frequencies,
 *               computes intermediate sums, and assigns Huffman codes
 *               to symbols. Outputs a 20-bit encoded vector for 5 symbols.
 *
 * KEY FEATURES:
 *   1. Frequency Sorting: Multi-stage pairwise comparison and swap
 *   2. Intermediate Computation: Computes sums of selected frequencies
 *      to guide Huffman code assignment
 *   3. Code Assignment: Nested conditional logic to generate 4-bit codes
 *   4. Output Encoding: Maps assigned codes to a single 20-bit vector
 *
 * DATA STRUCTURES:
 *   - symbol_freq[24:0] : Input frequency vector (5 symbols x 5 bits)
 *   - indata[4:0][1:0]  : Input array storing frequency and index
 *   - sort1..sort6[4:0][1:0] : Multi-stage sorted frequency arrays
 *   - compute1..compute10 : Intermediate sums for Huffman assignment
 *   - out[4:0][1:0]     : Temporary storage for assigned codes
 *   - out_encoded[19:0]  : Final concatenated Huffman codes for output
 *
 * ALGORITHM OVERVIEW:
 *   1. Input Assignment:
 *      - Split symbol_freq into 5 frequency values
 *      - Assign corresponding symbol indices
 *   2. Sorting:
 *      - Perform multi-stage pairwise comparisons to sort symbols by freq
 *   3. Intermediate Computation:
 *      - Calculate sums of selected frequencies to determine code priorities
 *   4. Code Assignment:
 *      - Use combinational if-else blocks to assign 4-bit Huffman codes
 *   5. Output Mapping:
 *      - Map codes according to symbol indices into a 20-bit vector
 *
 * DESIGN NOTES:
 *   - Uses continuous assignment for frequency sorting
 *   - Uses always@(*) blocks for combinational code assignment
 *   - Modular sorting stages allow easy modification for different symbol counts
 *   - Output mapping ensures consistent ordering of encoded symbols
 *
 * COMPLEXITY ANALYSIS:
 *   - Time Complexity: O(1), purely combinational logic
 *   - Space Complexity: O(1) registers/wires, fixed 5-symbol array
 *
 * MODIFICATION HISTORY:
 *   Date        Description
 *
 **************************************************************************/
