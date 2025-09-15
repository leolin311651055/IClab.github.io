Lab06  

這次上課主要是在操作 Synopsys Design Compiler，把 RTL 轉成 gate-level netlist。一開始我對 compile strategy 和 constraint 的設定還蠻不習慣的，常常 compile 後還是會出現 timing violation，需要花時間去 debug。最讓我頭疼的是多重實例的處理，如果沒有用 uniquify 或 compile-once-don’t-touch，同一個模組重複使用就容易出錯。  

做 SDF timing simulation 的時候才真的感受到 gate-level 電路的 delay，不再只是抽象的 always block，看著模擬結果跟理論不同，才明白 timing 的重要性。generate 和 for loop 真的很方便，可以動態產生多個 module，但剛開始寫 parameter 動態產生 module 時很容易弄錯 index，需要小心檢查。  

整堂課下來，雖然 compile 常常失敗、debug 很久，但慢慢地我對 Design Compiler 的流程越來越熟悉，從 RTL 到 gate 到 timing simulation 的每一步都可以自己操作，成功 compile 後有種把抽象電路「實體化」的成就感。

TOP Algorithm:
 
//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//    Date       : 2025
//    Version    : v1.0
//    File Name  : BCH_TOP.v
//    Module Name: BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//
// Algorithm Notes for BCH_TOP.v
//
// Overview:
// This module implements the top-level BCH decoder using syndrome inputs.
// The key algorithmic steps are divided into multiple states within a
// finite state machine (FSM). The module uses a soft IP for polynomial
// division and table lookups for Galois Field arithmetic.
//
// Key Steps:
//
// 1. Input Stage (INPUT):
//    - Receive 4-bit syndrome inputs.
//    - Load the divisor coefficients with the incoming syndrome.
//    - Initialize dividend to all '1's.
//
// 2. Degree Sorting (SORT):
//    - Determine the degrees of quotient and divisor polynomials.
//    - Update Omega_degree_sort and Sigma_degree_sort arrays.
//    - This is used for later GF multiplication and alignment.
//
// 3. Polynomial Division (DIVISION):
//    - Use the Division_IP soft IP to perform polynomial division.
//    - Compute quotient and remainder for Omega and Sigma polynomials.
//    - Division is done in GF(16), using log/antilog tables.
//
// 4. Compute Omega Polynomial (OMEGA_Q / OMEGA_Divisor / OMEGA):
//    - Multiply quotient or divisor with divisor/quotient in GF(16).
//    - Use table lookup for GF addition and multiplication.
//    - Handle special cases where values are 'f' (representing infinity/invalid).
//
// 5. Compute Sigma Polynomial (SIGMA_Q / SIGMA_S / SIGMA):
//    - Multiply Sigma polynomials using similar GF(16) operations.
//    - Update Sigma_0 and Sigma_1 registers with intermediate results.
//
// 6. Degree Counting (COUNT_DEG):
//    - Compute the degrees of Omega and Sigma after multiplication.
//    - This determines if polynomial correction can proceed.
//
// 7. Check Division Requirement (DIV_OR_NOT):
//    - If Sigma_degree <= 3 and Omega_degree <= 2, proceed to output computation.
//    - Otherwise, repeat sorting and recomputation.
//
// 8. Output Computation (COMPUTE_OUT):
//    - Compute the output error locations based on Sigma polynomial roots.
//    - Use modulo 15 arithmetic for GF(16) alignment.
//    - Store valid output locations in out_data array.
//
// 9. Output Stage (OUTPUT):
//    - Set out_valid high to indicate data is ready.
//    - Output the decoded error locations from out_data.
//
// Notes on Algorithmic Implementation:
//
// - GF(16) Arithmetic:
//   * Multiplication and addition are implemented via tables:
//     - tables_idx_to_int: map index to GF integer
//     - tables_int_to_idx: map GF integer back to index
//   * Operations handle modulo-15 reduction.
//   * 'f' (4'b1111) represents invalid/infinity value in GF(16).
//
// - Degree Computation:
//   * Degree arrays (Quotient_degree_sort, Divisor_degree_sort, Omega_degree_sort, Sigma_degree_sort)
//     are used to track the highest non-'f' coefficient.
//   * This helps in aligning polynomials for GF multiplication.
//
// - FSM Flow:
//   * FSM moves through states: IDLE -> INPUT -> SORT -> OMEGA_Q / OMEGA_Divisor -> OMEGA
//     -> SIGMA_Q / SIGMA_S -> SIGMA -> COUNT_DEG -> DIV_OR_NOT -> COMPUTE_OUT -> OUTPUT
//   * Counters counter_1 and counter_2 are used for iteration and output indexing.
//
// - Parallel Computation:
//   * Many operations are implemented combinationally for speed.
//   * Registers are updated at posedge of clk or negedge of rst_n.
//
// Summary:
// This module implements the BCH error location algorithm by processing the input syndrome
// polynomials, performing GF(16) arithmetic using tables, calculating Omega and Sigma
// polynomials, and outputting the error locations after polynomial evaluation. It is
// fully pipelined through FSM states with polynomial division handled by a soft IP.
//
//############################################################################


Division Algorithm:

//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//    Date       : 2023/10
//    Version    : v1.0
//    File Name  : Division_IP.v
//    Module Name: Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//
// Algorithm Notes for Division_IP.v
//
// Overview:
// This module implements polynomial division in GF(16) for BCH decoding.
// The inputs are dividend and divisor polynomials, each represented as 
// 4-bit coefficients for IP_WIDTH terms. The output is the quotient polynomial.
//
// Key Steps:
//
// 1. Input Preparation:
//    - Extract 4-bit coefficients from IN_Dividend and IN_Divisor into arrays.
//    - Initialize the point_head arrays for dividend and divisor to track
//      the first non-'f' (invalid/infinity) coefficient.
//
// 2. Sorting/Point Head:
//    - Compute point_head_Dividend and point_head_Divisor arrays to identify 
//      the leading coefficient of dividend/divisor in each iteration.
//    - This ensures proper alignment for division in GF(16).
//
// 3. Division Iteration (Generate Block):
//    For i = 0 to IP_WIDTH-1:
//      a. Max Degree Division:
//         - If the current dividend coefficient is valid (not 15), compute 
//           the GF(16) division of leading coefficients using modulo-15 arithmetic.
//         - Store the result in div_coeff_ans[i].
//      b. Update div_power_ans[i] to track the power of the quotient term.
//      c. Multiply Divisor by quotient term (Divisor_coeff_after_mult):
//         - Add div_coeff_ans[i] to each divisor coefficient in GF(16) using tables.
//         - Handle wrap-around modulo 15; '15' represents infinity.
//      d. XOR Dividend with multiplied divisor to get new remainder:
//         - Use tables_idx_to_int and tables_int_to_idx for GF(16) addition.
//         - Update Dividend_coeff_after_xor for next iteration.
//
// 4. Output Quotient Computation:
//    - Compute ans_count as the difference in degrees of dividend and divisor.
//    - Fill OUT_Quotient array with div_coeff_ans in proper order.
//    - Set remaining positions to 'f' (4'b1111) if quotient is shorter than IP_WIDTH.
//
// Notes on GF(16) Arithmetic:
//
// - GF(16) tables:
//   * tables_idx_to_int: map GF index to integer for multiplication/addition.
//   * tables_int_to_idx: map integer result back to GF index.
// - Coefficient value '15' represents infinity/invalid.
// - All operations are modulo 15 for GF(16) arithmetic.
//
// Optimization Notes:
//
// - Dividend_coeff_after_xor_temp is used for intermediate XOR computation.
// - point_head arrays allow efficient degree tracking without full sorting.
// - Fully combinational for each generate iteration for speed.
//
// Summary:
// Division_IP.v implements polynomial division for BCH decoding in GF(16). 
// It iteratively computes quotient coefficients by dividing the leading terms 
// of the dividend and divisor, multiplying the divisor by this quotient, 
// XOR-ing it with the dividend to produce the next remainder, and finally 
// outputting the quotient polynomial.
//
//############################################################################
