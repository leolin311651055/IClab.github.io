Lab03

這次課主要學 STA（Static Timing Analysis），不用模擬就能檢查電路時序，核心是找 Critical Path 和 Worst-Case Delay，把電路當 DAG，用 Longest Path 算法求解。  

作業是 STA.v 和 PATTERN.v：STA.v 計算每個 pattern 的 worst_delay 和 critical path，PATTERN.v 則設計 testbench 控制輸入、檢查輸出，確保設計符合規範，把演算法套進硬體驗證。  

收穫最大的是練習 testbench。以前寫 RTL 只做電路，這次要自己設計 pattern 來驗證功能，才體會 in_valid/out_valid 控制的重要性，延遲要算準，corner case 也要顧到。  

整體來說，STA 原理不難，但 testbench 設計才是挑戰，這次讓我對時序驗證流程更熟悉，也體會 pattern 設計在實務驗證的重要性。
