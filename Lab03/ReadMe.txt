Lab03

這次課主要學 STA（Static Timing Analysis），不用模擬就能檢查電路時序，核心是找 Critical Path 和 Worst-Case Delay，把電路當 DAG，用 Longest Path 算法求解。  

作業是 STA.v 和 PATTERN.v：STA.v 計算每個 pattern 的 worst_delay 和 critical path，PATTERN.v 則設計 testbench 控制輸入、檢查輸出，確保設計符合規範，把演算法套進硬體驗證。  

收穫最大的是練習 testbench。以前寫 RTL 只做電路，這次要自己設計 pattern 來驗證功能，才體會 in_valid/out_valid 控制的重要性，延遲要算準，corner case 也要顧到。  

整體來說，STA 原理不難，但 testbench 設計才是挑戰，這次讓我對時序驗證流程更熟悉，也體會 pattern 設計在實務驗證的重要性。


Algorithm: 

/**************************************************************************
 * MODULE      : STA (Static Timing Analysis)
 * FILE NAME   : STA.v
 * VERSION     : 1.0
 * DATE        : 2025/02/26
 * AUTHOR      : Yu-Hao Cheng, NYCU IEE
 * DESCRIPTION : ICLAB 2025 Spring / LAB3 / STA
 *               Implements timing analysis to find the critical path,
 *               worst-case delay, and corresponding path in a digital 
 *               circuit. The design uses a state machine for input, 
 *               path computation, and output.
 * 
 * KEY FEATURES:
 *   1. Multi-stage FSM: IDLE -> INPUT -> PATH -> FINDPATH -> OUTPUT
 *   2. Supports up to 16 nodes and 32 edges (source-destination pairs)
 *   3. Computes worst-case delay via iterative update of Max_Value
 *   4. Tracks previous nodes for critical path reconstruction
 *   5. Handles asynchronous reset and synchronous data input
 *
 * DATA STRUCTURES:
 *   - in_source[0:31], in_destination[0:31] : Edge lists
 *   - Self_Delay[0:15]                       : Node intrinsic delays
 *   - Max_Value[0:15]                         : Maximum arrival time per node
 *   - Path_Previous[0:15]                     : Previous node in critical path
 *   - done[0:31], node_done[0:15], on[0:31]  : FSM control flags for path traversal
 *   - answer[0:15]                            : Stores reconstructed critical path
 *
 * ALGORITHM OVERVIEW:
 *   1. Input Stage:
 *      - Capture source, destination, and delay for each edge/node
 *   2. Path Computation:
 *      - For active edges (on[i] == 1), update Max_Value:
 *          Max_Value[dest] = max(Max_Value[dest], Max_Value[src] + Self_Delay[dest])
 *      - Update Path_Previous to track source of current max delay
 *   3. Critical Path Reconstruction:
 *      - Traverse Path_Previous backward from destination node to reconstruct path
 *   4. Output Stage:
 *      - Output worst_delay and critical path sequence
 *
 * DESIGN NOTES:
 *   - Uses blocking assignments in combinational logic to handle index-dependent updates
 *   - Multiple conditional branches ensure correct priority updates in parallel paths
 *   - FSM ensures sequential data processing and proper timing of output signals
 *   - Modular design allows scalability for larger circuits
 *
 * MODIFICATION HISTORY:
 *   Date        Description
 *
 **************************************************************************/
