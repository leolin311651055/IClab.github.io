Lab05

這次課主要介紹 Macro 與 SRAM。老師講 Soft/Firm/Hard Macro 的差別，尤其 Hard Macro 固定布線，可搬移或翻轉但不能改內部設計，挺新鮮。SRAM 部分讓我理解單埠/雙埠、OE/CS/WEB 控制，以及 timing 注意事項。作業讓我第一次用 Memory Compiler 生成 SRAM，整合到 RTL 裡，每個小細節都會影響時序。  

作業是 Motion Vector Difference Matching (MVDM)：先接收 L0/L1 影像存 SRAM，再算 BI_8x8，最後 Mirror MVD Matching 計算 SAD 找最小值輸出。流程像流水線，每個步驟 timing 都要小心。  

這次我主要練 testbench，驗證資料正確性，透過 debug 理解 SRAM、BI 和 SAD 的計算方式。整體收穫是實際操作 Macro、SRAM、Memory Compiler，並體會 testbench 在驗證流程的重要性，對理解硬體設計流程幫助很大。
